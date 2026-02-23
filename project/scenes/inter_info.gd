extends RichTextLabel

func _ready():
	self.visible = false

	SubtitleScene.dialog_finished.connect(
		func():
			self.visible = true
	)

	SubtitleScene.dialog_started.connect(
		func():
			self.visible = false
	)
