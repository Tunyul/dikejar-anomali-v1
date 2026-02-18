extends Control

func _ready():
	print("[MobileControls] Script Ready")
	# Pastikan node ini selalu terlihat di mobile
	visible = true
	# Paksa z-index tinggi agar tidak tertutup
	z_index = 100

	# Verifikasi tombol
	for child in get_children():
		if child is TouchScreenButton:
			child.visible = true
			print("[MobileControls] Button visible: ", child.name)
			# Tambahkan efek visual saat ditekan jika belum ada
			if child.action == "jump":
				print("[MobileControls] Jump button ready")
			elif child.action == "attack":
				print("[MobileControls] Attack button ready")

func _process(_delta):
	if not is_inside_tree():
		return

	# Jika karena suatu hal node ini tersembunyi, paksa tampilkan kembali
	if not visible:
		visible = true
		print("[MobileControls] Forced visibility in _process")
