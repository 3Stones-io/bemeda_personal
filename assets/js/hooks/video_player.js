import videojs from 'video.js'

export default {
  mounted() {
    let controlBarComponents = [
      'playToggle',
      'volumePanel',
      'currentTimeDisplay',
      'progressControl',
      'durationDisplay',
      'fullscreenToggle',
    ]

    if ('exitPictureInPicture' in document) {
      controlBarComponents.splice(
        controlBarComponents.length - 1,
        0,
        'pictureInPictureToggle'
      )
    }

    let player = videojs(this.el, {
      controlBar: {
        children: controlBarComponents,
      },
    })
    player.play()
    window.player = player
  },
}
