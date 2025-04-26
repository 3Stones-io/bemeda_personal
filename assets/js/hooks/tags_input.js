const TagsInput = {
  mounted() {
    const tagInput = this.el.querySelector('#tag-input')
    
    const addTag = (tagValue) => {
      const tagValue = tagInput.value.trim()
      if (tagValue && tagValue.length > 0) {
        this.pushEvent('add-tag', { name: tagValue })
        tagInput.value = ''
      }
    }

    tagInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ',') {
        e.preventDefault()
        addTag()
      }
    })
  },

}

export default TagsInput 