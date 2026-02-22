extends RichTextLabel

func _ready():
	self.visible = false

	SubtitlesScene.dialog_finished.connect(
		func():
			self.visible = true
	)

	SubtitlesScene.dialog_started.connect(
		func():
			self.visible = false
	)
