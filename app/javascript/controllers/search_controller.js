import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "section"]

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.rowTargets.forEach(row => {
      row.classList.toggle("hidden", !row.dataset.name.toLowerCase().includes(query))
    })
    this.sectionTargets.forEach(section => {
      const hasVisible = [...section.querySelectorAll("[data-search-target='row']")]
        .some(row => !row.classList.contains("hidden"))
      section.classList.toggle("hidden", !hasVisible)
    })
  }
}
