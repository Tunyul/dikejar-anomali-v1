extends Node

# Signal untuk UI atau Game Logic
signal connection_status_changed(is_connected: bool)
signal product_details_received(products: Array) # Array of Dictionary
signal purchase_successful(product_id: String)
signal purchase_failed(error_message: String)
signal purchase_cancelled()

var payment = null
var is_connected = false

# Definisi Product ID (Harus sama dengan di Google Play Console)
# Contoh: "remove_ads", "coin_pack_100", dll.
const PRODUCTS = [
	"remove_ads",
	"coin_pack_small",
	"coin_pack_medium",
	"coin_pack_large"
]

func _ready():
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment = Engine.get_singleton("GodotGooglePlayBilling")

		# Hubungkan signal dari plugin
		payment.connected.connect(_on_connected)
		payment.disconnected.connect(_on_disconnected)
		payment.connect_error.connect(_on_connect_error)
		payment.purchases_updated.connect(_on_purchases_updated)
		payment.purchase_error.connect(_on_purchase_error)
		payment.product_details_query_completed.connect(_on_product_details_query_completed)
		payment.product_details_query_error.connect(_on_product_details_query_error)
		payment.billing_resume.connect(_on_billing_resume) # Untuk menangani purchase yang belum selesai saat resume

		# Mulai koneksi
		start_connection()
	else:
		print("BillingManager: Android Google Play Billing plugin not found!")

func start_connection():
	if payment:
		payment.startConnection()

func _on_connected():
	print("BillingManager: Connected to Google Play Billing")
	is_connected = true
	emit_signal("connection_status_changed", true)

	# Langsung query detail produk setelah konek
	query_products()

	# Cek apakah ada pembelian yang belum diclaim (misal user uninstall lalu install lagi)
	payment.queryPurchases("inapp") # "inapp" atau "subs"

func query_products():
	if payment and is_connected:
		payment.queryProductDetails(PRODUCTS, "inapp")

func purchase(product_id: String):
	if payment and is_connected:
		var response = payment.purchase(product_id)
		if response.status != OK:
			emit_signal("purchase_failed", "Purchase request failed: " + str(response.response_code))
	else:
		emit_signal("purchase_failed", "Billing service not connected")

# Callback saat detail produk diterima (harga, deskripsi, dll)
func _on_product_details_query_completed(product_details):
	print("BillingManager: Product details received: ", product_details)
	emit_signal("product_details_received", product_details)

func _on_product_details_query_error(response_id, error_message, products_invalid):
	print("BillingManager: Product query error: ", error_message)

func _on_purchases_updated(purchases):
	for purchase in purchases:
		if purchase.purchase_state == 1: # 1 = PURCHASED
			_handle_purchase(purchase)

func _handle_purchase(purchase):
	var product_id = purchase.products[0] # Biasanya array, ambil yang pertama

	# Jika produk adalah consumable (bisa dibeli berkali-kali, misal koin), harus di-consume
	if "coin" in product_id:
		payment.consumePurchase(purchase.purchase_token)

	# Jika produk adalah non-consumable (sekali beli, misal remove ads), harus di-acknowledge
	if "remove_ads" in product_id and not purchase.is_acknowledged:
		payment.acknowledgePurchase(purchase.purchase_token)

	# Beritahu game logic bahwa pembelian sukses
	emit_signal("purchase_successful", product_id)

func _on_purchase_error(response_id, error_message):
	print("BillingManager: Purchase error: ", error_message)
	if "User cancelled" in error_message:
		emit_signal("purchase_cancelled")
	else:
		emit_signal("purchase_failed", error_message)

func _on_disconnected():
	print("BillingManager: Disconnected")
	is_connected = false
	emit_signal("connection_status_changed", false)

func _on_connect_error(response_id, error_message):
	print("BillingManager: Connect error: ", error_message)
	is_connected = false
	emit_signal("connection_status_changed", false)

func _on_billing_resume():
	# Cek lagi pembelian saat aplikasi di-resume
	if payment:
		payment.queryPurchases("inapp")
