import { Controller } from "@hotwired/stimulus"

const GREEN = "#537326"
const ADD_GREEN = "#4a7c3f"

export default class extends Controller {
  connect() {
    this.busy = false
    this.state = this.loadState()
    this.render()
    this.fetchData()
    this.pollTimer = setInterval(() => this.checkConnection(), 5000)
    this.checkConnection()
  }

  disconnect() {
    clearInterval(this.pollTimer)
  }

  // ── State ──────────────────────────────────────────────────────────────

  loadState() {
    try {
      const saved = JSON.parse(localStorage.getItem("camp_store_state") || "{}")
      return {
        campers: saved.campers || [],
        products: saved.products || [],
        carts: saved.carts || {},       // { "camper_id": [{id?, product_id, product_name, product_price, quantity, offline?}] }
        purchases: saved.purchases || {}, // { "camper_id": [{...}] }
        queue: saved.queue || [],        // [{type:'checkout', camper_id, offline_items:[]}]
        online: true,
        view: "list",
        camperId: null,
        search: ""
      }
    } catch { return this.emptyState() }
  }

  emptyState() {
    return { campers: [], products: [], carts: {}, purchases: {}, queue: [], online: true, view: "list", camperId: null, search: "" }
  }

  saveState() {
    const { campers, products, carts, purchases, queue } = this.state
    localStorage.setItem("camp_store_state", JSON.stringify({ campers, products, carts, purchases, queue }))
  }

  // ── Data & Connection ──────────────────────────────────────────────────

  async fetchData() {
    try {
      const resp = await fetch("/api/data", { cache: "no-cache" })
      if (!resp.ok) return
      const data = await resp.json()
      this.state.campers = data.campers
      this.state.products = data.products
      // Merge carts: keep offline items, replace server items
      const newCarts = data.carts || {}
      for (const [cid, items] of Object.entries(newCarts)) {
        const offline = (this.state.carts[cid] || []).filter(i => i.offline)
        this.state.carts[cid] = [...items, ...offline]
      }
      // For campers with no server cart data but with offline items, preserve them
      for (const [cid, items] of Object.entries(this.state.carts)) {
        if (!newCarts[cid]) {
          this.state.carts[cid] = items.filter(i => i.offline)
        }
      }
      this.state.purchases = data.purchases
      this.saveState()
      this.render()
      if (this.state.online && this.state.queue.length > 0) this.syncQueue()
    } catch { /* stay with cached state */ }
  }

  async checkConnection() {
    const wasOnline = this.state.online
    try {
      const resp = await fetch("/up", { cache: "no-cache", signal: AbortSignal.timeout(3000) })
      this.state.online = resp.ok
    } catch {
      this.state.online = false
    }
    this.updateNav()
    if (!wasOnline && this.state.online) {
      await this.fetchData()
      if (this.state.queue.length > 0) await this.syncQueue()
    }
  }

  async syncQueue() {
    const queue = [...this.state.queue]
    const synced = []
    for (const action of queue) {
      try {
        if (action.type === "checkout") {
          for (const item of action.offline_items) {
            for (let i = 0; i < item.quantity; i++) {
              await this.apiAddToCart(action.camper_id, item.product_id)
            }
          }
          await this.apiCheckout(action.camper_id)
          synced.push(action)
        }
      } catch { break }
    }
    this.state.queue = queue.filter(a => !synced.includes(a))
    this.saveState()
    this.updateNav()
    if (synced.length > 0) await this.fetchData()
  }

  // ── Nav ────────────────────────────────────────────────────────────────

  updateNav() {
    const online = this.state.online
    const count = this.state.queue.length
    const dot = document.getElementById("nav-dot")
    const text = document.getElementById("nav-text")
    const pending = document.getElementById("nav-pending")
    if (dot) dot.className = `w-2 h-2 rounded-full inline-block ${online && count === 0 ? "bg-green-400" : "bg-red-400"}`
    if (text) text.textContent = online ? "Online" : "Offline"
    if (pending) {
      pending.textContent = count > 0 ? `· ${count} unsynced` : ""
      pending.classList.toggle("hidden", count === 0)
    }
  }

  // ── Routing ────────────────────────────────────────────────────────────

  showCamper(event) {
    const id = parseInt(event.currentTarget.dataset.camperId)
    this.state.camperId = id
    this.state.view = "detail"
    this.state.search = ""
    this.render()
  }

  showList(event) {
    this.state.view = "list"
    this.state.camperId = null
    this.state.search = ""
    this.render()
  }

  // ── Search ─────────────────────────────────────────────────────────────

  filterCampers(event) {
    const q = event.target.value.toLowerCase()
    this.element.querySelectorAll("[data-camper-row]").forEach(row => {
      row.classList.toggle("hidden", !row.dataset.name.toLowerCase().includes(q))
    })
  }

  filterProducts(event) {
    const q = event.target.value.toLowerCase()
    const container = document.getElementById("product-list")
    if (!container) return
    container.querySelectorAll("[data-product-row]").forEach(row => {
      row.classList.toggle("hidden", !row.dataset.name.toLowerCase().includes(q))
    })
    container.querySelectorAll("[data-section-block]").forEach(block => {
      const visible = [...block.querySelectorAll("[data-product-row]")].some(r => !r.classList.contains("hidden"))
      block.classList.toggle("hidden", !visible)
    })
  }

  // ── Cart Actions ───────────────────────────────────────────────────────

  async addToCart(event) {
    if (this.busy) return
    const productId = parseInt(event.currentTarget.dataset.productId)
    const product = this.state.products.find(p => p.id === productId)
    if (!product) return
    const camperId = this.state.camperId

    if (this.state.online) {
      this.busy = true
      try {
        await this.apiAddToCart(camperId, productId)
        await this.fetchData()
      } catch { this.showToast("Failed to add item", "red") }
      this.busy = false
    } else {
      const key = String(camperId)
      const cart = this.state.carts[key] || []
      const existing = cart.find(i => i.product_id === productId && i.offline)
      if (existing) {
        existing.quantity++
      } else {
        cart.push({ product_id: productId, product_name: product.name, product_price: product.price, quantity: 1, offline: true })
      }
      this.state.carts[key] = cart
      this.saveState()
      this.render()
    }
  }

  async incrementItem(event) {
    await this.adjustItem(event, "up")
  }

  async decrementItem(event) {
    await this.adjustItem(event, "down")
  }

  async adjustItem(event, direction) {
    if (this.busy) return
    const li = event.currentTarget.closest("li")
    const itemId = li.dataset.itemId
    const productId = parseInt(li.dataset.productId)
    const isOffline = li.dataset.offline === "true"
    const camperId = this.state.camperId
    const key = String(camperId)

    if (isOffline) {
      const cart = this.state.carts[key] || []
      const item = cart.find(i => i.product_id === productId && i.offline)
      if (!item) return
      if (direction === "up") {
        item.quantity++
      } else {
        if (item.quantity > 1) {
          item.quantity--
        } else {
          if (!confirm(`Remove ${item.product_name} from cart?`)) return
          this.state.carts[key] = cart.filter(i => !(i.product_id === productId && i.offline))
        }
      }
      this.saveState()
      this.render()
    } else if (this.state.online) {
      this.busy = true
      try {
        await this.apiUpdateCartItem(camperId, itemId, direction)
        await this.fetchData()
      } catch { this.showToast("Failed to update cart", "red") }
      this.busy = false
    } else {
      this.showToast("Can't modify cart items while offline")
    }
  }

  async removeItem(event) {
    if (this.busy) return
    const li = event.currentTarget.closest("li")
    const itemId = li.dataset.itemId
    const productId = parseInt(li.dataset.productId)
    const productName = li.dataset.productName
    const isOffline = li.dataset.offline === "true"
    const camperId = this.state.camperId
    const key = String(camperId)

    if (!confirm(`Remove ${productName} from cart?`)) return

    if (isOffline) {
      this.state.carts[key] = (this.state.carts[key] || []).filter(i => !(i.product_id === productId && i.offline))
      this.saveState()
      this.render()
    } else if (this.state.online) {
      this.busy = true
      try {
        await this.apiRemoveCartItem(camperId, itemId)
        await this.fetchData()
      } catch { this.showToast("Failed to remove item", "red") }
      this.busy = false
    } else {
      this.showToast("Can't remove cart items while offline")
    }
  }

  async checkout(event) {
    if (this.busy) return
    const camperId = this.state.camperId
    const key = String(camperId)
    const cart = this.state.carts[key] || []
    if (cart.length === 0) return

    const total = cart.reduce((s, i) => s + i.product_price * i.quantity, 0)
    if (!confirm(`Complete purchase for $${total.toFixed(2)}?`)) return

    if (this.state.online) {
      this.busy = true
      try {
        const offlineItems = cart.filter(i => i.offline)
        for (const item of offlineItems) {
          for (let i = 0; i < item.quantity; i++) {
            await this.apiAddToCart(camperId, item.product_id)
          }
        }
        const resp = await this.apiCheckout(camperId)
        if (!resp.ok) {
          const body = await resp.json().catch(() => ({}))
          this.showToast(body.error || "Checkout failed", "red")
        }
        await this.fetchData()
      } catch { this.showToast("Checkout failed", "red") }
      this.busy = false
    } else {
      const offlineItems = cart.filter(i => i.offline)
      this.state.queue.push({
        type: "checkout",
        camper_id: camperId,
        offline_items: offlineItems.map(i => ({ product_id: i.product_id, quantity: i.quantity }))
      })

      // Optimistic update
      const camper = this.state.campers.find(c => c.id === camperId)
      if (camper) camper.balance = parseFloat((camper.balance - total).toFixed(2))

      const now = new Date()
      const timeStr = now.toLocaleString("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })
      const newPurchases = cart.map(i => ({
        id: `offline-${Date.now()}-${i.product_id}`,
        product_name: i.product_name,
        quantity: i.quantity,
        price_at_purchase: i.product_price,
        created_at: timeStr,
        offline: true
      }))
      this.state.purchases[key] = [...newPurchases, ...(this.state.purchases[key] || [])]
      this.state.carts[key] = []

      this.saveState()
      this.updateNav()
      this.render()
      this.showToast("Purchase saved — will sync when back online", "green")
    }
  }

  // ── Server API ─────────────────────────────────────────────────────────

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  jsonHeaders() {
    return { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrfToken }
  }

  async apiAddToCart(camperId, productId) {
    return fetch(`/campers/${camperId}/cart_items`, {
      method: "POST", headers: this.jsonHeaders(),
      body: JSON.stringify({ product_id: productId })
    })
  }

  async apiUpdateCartItem(camperId, itemId, direction) {
    return fetch(`/campers/${camperId}/cart_items/${itemId}`, {
      method: "PATCH", headers: this.jsonHeaders(),
      body: JSON.stringify({ direction })
    })
  }

  async apiRemoveCartItem(camperId, itemId) {
    return fetch(`/campers/${camperId}/cart_items/${itemId}`, {
      method: "DELETE", headers: this.jsonHeaders()
    })
  }

  async apiCheckout(camperId) {
    return fetch(`/campers/${camperId}/purchases`, {
      method: "POST", headers: this.jsonHeaders()
    })
  }

  // ── Render ─────────────────────────────────────────────────────────────

  render() {
    if (this.state.view === "list") {
      this.element.innerHTML = this.renderCamperList()
    } else {
      this.element.innerHTML = this.renderCamperDetail()
    }
    this.updateNav()
  }

  renderCamperList() {
    const { campers } = this.state
    const rows = campers.length === 0
      ? `<tr><td colspan="2" class="px-6 py-8 text-center text-stone-400 text-sm italic">Loading campers...</td></tr>`
      : campers.map(c => {
          const neg = c.balance < 0
          const bal = `${neg ? "-" : ""}$${Math.abs(c.balance).toFixed(2)}`
          return `<tr data-camper-row data-name="${this.h(c.name)}"
                      data-camper-id="${c.id}"
                      data-action="click->store#showCamper"
                      class="hover:bg-amber-50 transition-colors cursor-pointer">
            <td class="px-6 py-4 font-semibold text-stone-700">${this.h(c.name)}</td>
            <td class="px-6 py-4 text-right font-semibold ${neg ? "text-red-600" : "text-green-800"}">${bal}</td>
          </tr>`
        }).join("")

    return `
      <div class="mb-6 flex items-end justify-between gap-4">
        <div>
          <h1 class="serif text-3xl font-bold text-stone-800 mb-1">Campers</h1>
          <p class="text-stone-500 text-sm">Select a camper to view their balance and make purchases.</p>
        </div>
      </div>
      <div>
        <div class="mb-4">
          <input type="text" autofocus placeholder="Search campers..."
            data-action="input->store#filterCampers"
            class="w-full px-4 py-2 border border-stone-300 rounded shadow-sm bg-white text-stone-800 placeholder-stone-400 focus:outline-none text-sm">
        </div>
        <div class="bg-white rounded-md shadow-sm border border-stone-200 overflow-hidden">
          <table class="min-w-full divide-y divide-stone-200">
            <thead>
              <tr style="background-color: ${GREEN};">
                <th class="px-6 py-3 text-left text-xs font-semibold text-stone-300 uppercase tracking-widest">Camper</th>
                <th class="px-6 py-3 text-right text-xs font-semibold text-stone-300 uppercase tracking-widest">Remaining Balance</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-stone-100">${rows}</tbody>
          </table>
        </div>
      </div>`
  }

  renderCamperDetail() {
    const camperId = this.state.camperId
    const camper = this.state.campers.find(c => c.id === camperId)
    if (!camper) return `<p class="text-stone-400">Loading...</p>`

    const neg = camper.balance < 0
    const bal = `${neg ? "-" : ""}$${Math.abs(camper.balance).toFixed(2)}`

    return `
      <div class="flex items-start justify-between mb-8">
        <div>
          <button data-action="click->store#showList"
            class="text-stone-500 hover:text-green-800 text-sm mb-2 inline-block transition-colors">&larr; All Campers</button>
          <h1 class="serif text-3xl font-bold text-stone-800">${this.h(camper.name)}</h1>
        </div>
        <div class="text-right bg-white border border-stone-200 rounded shadow-sm px-6 py-4">
          <p class="text-xs uppercase tracking-widest text-stone-400 mb-1">Balance</p>
          <p class="serif text-4xl font-bold ${neg ? "text-red-600" : "text-green-800"}">${bal}</p>
        </div>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="lg:col-span-2">${this.renderStoreItems()}</div>
        <div class="lg:col-span-1 flex flex-col gap-8 sticky top-4 self-start max-h-[calc(100vh-2rem)] overflow-y-auto">
          ${this.renderCart(camperId)}
          ${this.renderHistory(camperId)}
        </div>
      </div>`
  }

  renderStoreItems() {
    const { products } = this.state
    const bySection = products.reduce((acc, p) => {
      (acc[p.section] = acc[p.section] || []).push(p)
      return acc
    }, {})

    const sections = Object.entries(bySection).map(([section, prods], i) => `
      <div data-section-block class="${i > 0 ? "border-t border-stone-100" : ""} px-5 py-4">
        <h3 class="text-xs font-semibold uppercase tracking-widest text-green-800 mb-3">${this.h(section)}</h3>
        <div class="space-y-1">
          ${prods.map(p => `
            <div data-product-row data-name="${this.h(p.name)}"
                 data-action="click->store#addToCart"
                 data-product-id="${p.id}"
                 class="flex items-center justify-between py-2 px-3 rounded hover:bg-amber-50 transition-colors cursor-pointer">
              <div>
                <span class="font-medium text-stone-800">${this.h(p.name)}</span>
                <span class="text-sm text-stone-500 ml-2">$${p.price.toFixed(2)}</span>
                <span class="text-xs text-stone-400 ml-1">(${p.quantity} left)</span>
              </div>
              <span class="text-white text-xs font-semibold px-3 py-1 rounded tracking-wide pointer-events-none"
                    style="background-color: ${ADD_GREEN};">+ Add</span>
            </div>`).join("")}
        </div>
      </div>`).join("")

    const body = products.length === 0
      ? `<p class="px-5 py-6 text-stone-400 text-sm italic">No items available.</p>`
      : `<div id="product-list">${sections}</div>`

    return `
      <div class="bg-white rounded-md shadow-sm border border-stone-200 overflow-hidden">
        <div class="px-5 py-4 border-b border-stone-200 flex items-center gap-3" style="background-color: ${GREEN};">
          <h2 class="serif text-lg font-semibold text-white flex-shrink-0">Store Items</h2>
          <input type="text" autofocus placeholder="Search..."
            data-action="input->store#filterProducts"
            class="flex-1 px-3 py-1 text-sm rounded border-0 bg-white/20 text-white placeholder-white/60 focus:outline-none min-w-0">
        </div>
        ${body}
      </div>`
  }

  renderCart(camperId) {
    const key = String(camperId)
    const items = this.state.carts[key] || []
    const total = items.reduce((s, i) => s + i.product_price * i.quantity, 0)

    const itemsHtml = items.length === 0
      ? `<p class="px-5 py-6 text-stone-400 text-sm italic">Your cart is empty.</p>`
      : `<ul class="divide-y divide-stone-100">
          ${items.map(item => {
            const subtotal = (item.product_price * item.quantity).toFixed(2)
            const isOffline = item.offline ? "true" : "false"
            const itemId = item.id || ""
            return `<li class="px-4 py-3 flex items-center justify-between gap-2 ${item.offline ? "bg-amber-50" : ""}"
                        data-item-id="${itemId}"
                        data-product-id="${item.product_id}"
                        data-product-name="${this.h(item.product_name)}"
                        data-offline="${isOffline}">
              <span class="font-medium text-stone-800 flex-1 text-sm">${this.h(item.product_name)}${item.offline ? '<span class="text-amber-400 ml-0.5">*</span>' : ""}</span>
              <div class="flex items-center gap-1">
                <button data-action="click->store#decrementItem"
                  class="w-6 h-6 flex items-center justify-center rounded border border-stone-300 text-stone-600 hover:bg-stone-100 font-bold leading-none transition-colors text-xs">−</button>
                <span class="w-5 text-center font-semibold text-stone-700 text-sm">${item.quantity}</span>
                <button data-action="click->store#incrementItem"
                  class="w-6 h-6 flex items-center justify-center rounded border border-stone-300 text-stone-600 hover:bg-stone-100 font-bold leading-none transition-colors text-xs">+</button>
              </div>
              <span class="text-stone-700 text-xs w-12 text-right">$${subtotal}</span>
              <button data-action="click->store#removeItem"
                class="text-stone-300 hover:text-red-500 text-xs font-bold transition-colors">✕</button>
            </li>`
          }).join("")}
        </ul>
        <div class="px-4 py-3 border-t border-stone-200 bg-stone-50 rounded-b-md flex items-center justify-between">
          <span class="font-semibold text-stone-700 text-sm">$${total.toFixed(2)}</span>
          <button data-action="click->store#checkout"
            class="text-white font-semibold px-4 py-1.5 rounded text-xs tracking-wide transition-colors"
            style="background-color: ${GREEN};">Checkout →</button>
        </div>`

    return `
      <div class="bg-white rounded-md shadow-sm border border-stone-200">
        <div class="px-5 py-4 border-b border-stone-200 rounded-t-md" style="background-color: ${GREEN};">
          <h2 class="serif text-lg font-semibold text-white">Cart</h2>
        </div>
        ${itemsHtml}
      </div>`
  }

  renderHistory(camperId) {
    const key = String(camperId)
    const purchases = this.state.purchases[key] || []

    const body = purchases.length === 0
      ? `<p class="px-5 py-6 text-stone-400 text-sm italic">No purchases yet.</p>`
      : `<ul class="divide-y divide-stone-100">
          ${purchases.map(p => `
            <li class="px-4 py-3 ${p.offline ? "bg-amber-50" : ""}">
              <div class="flex items-center justify-between">
                <div>
                  <span class="font-medium text-stone-800 text-sm">${this.h(p.product_name)}</span>
                  <span class="text-xs text-stone-500 ml-1">× ${p.quantity}</span>
                  ${p.offline ? '<span class="text-amber-400 ml-0.5">*</span>' : ""}
                </div>
                <span class="text-stone-700 font-semibold text-sm">$${(p.price_at_purchase * p.quantity).toFixed(2)}</span>
              </div>
              <p class="text-xs text-stone-400 mt-0.5">${p.created_at}</p>
            </li>`).join("")}
        </ul>`

    return `
      <div class="bg-white rounded-md shadow-sm border border-stone-200">
        <div class="px-5 py-4 border-b border-stone-200 rounded-t-md" style="background-color: ${GREEN};">
          <h2 class="serif text-lg font-semibold text-white">Purchase History</h2>
        </div>
        ${body}
      </div>`
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  h(str) {
    return String(str ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }

  showToast(message, color = "amber") {
    const bg = color === "green" ? "#15803d" : color === "red" ? "#b91c1c" : "#92400e"
    const el = document.createElement("div")
    el.className = "fixed bottom-4 right-4 text-white px-4 py-3 rounded shadow-lg text-sm z-50"
    el.style.backgroundColor = bg
    el.textContent = message
    document.body.appendChild(el)
    setTimeout(() => { el.style.transition = "opacity 0.4s"; el.style.opacity = "0"; setTimeout(() => el.remove(), 400) }, 3500)
  }
}
