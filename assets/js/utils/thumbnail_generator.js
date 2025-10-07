export default (file, boundBox) => {
  return new Promise((resolve, reject) => {
    const player = document.createElement('video')
    player.setAttribute('src', URL.createObjectURL(file))
    player.load()

    player.addEventListener('loadedmetadata', () => {
      // 'seeked' event doesn't fire otherwise in Safari
      setTimeout(() => {
        player.currentTime = 1.0
      }, 200)

      player.addEventListener('seeked', () => {
        const scaleRatio =
          Math.min(...boundBox) /
          Math.max(player.videoWidth, player.videoHeight)
        const width = player.videoWidth * scaleRatio
        const height = player.videoHeight * scaleRatio

        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height

        const ctx = canvas.getContext('2d')
        ctx.drawImage(player, 0, 0, width, height)

        return resolve(canvas.toDataURL(file.type))
      })
    })
  })
}
