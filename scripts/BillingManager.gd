extends Node

# Signal untuk UI atau Game Logic
signal connection_status_changed(is_connected: bool)
signal product_details_received(products: Array) # Array of Dictionary
signal purchase_successful(product_id: String)
signal purchase_failed(error_message: String)
signal purchase_cancelled()

var billing: BillingClient = null
var billing_connected = false

# Definisi Product ID (Harus sama dengan di Google Play Console)
# Contoh: "remove_ads", "coin_pack_100", dll.
const PRODUCTS = [
    "remove_ads",
    "coin_pack_small",
    "coin_pack_medium",
	"coin_pack_large"
]

func _ready():
    # Inisialisasi BillingClient
    billing = BillingClient.new()
    add_child(billing)

    # Hubungkan signal dari plugin
    billing.connected.connect(_on_connected)
    billing.disconnected.connect(_on_disconnected)
    billing.connect_error.connect(_on_connect_error)
    billing.query_product_details_response.connect(_on_product_details_query_completed)
    billing.query_purchases_response.connect(_on_purchases_query_completed)
    billing.on_purchase_updated.connect(_on_purchases_updated)
    billing.consume_purchase_response.connect(_on_consume_purchase_response)
    billing.acknowledge_purchase_response.connect(_on_acknowledge_purchase_response)

    # Mulai koneksi
    start_connection()

func start_connection():
    if billing:
        billing.start_connection()

func _on_connected():
    print("BillingManager: Connected to Google Play Billing")
    billing_connected = true
    emit_signal("connection_status_changed", true)

    # Langsung query detail produk setelah konek
    query_products()

    # Cek apakah ada pembelian yang belum diclaim (misal user uninstall lalu install lagi)
    # Menggunakan query_purchases untuk restore
    if billing:
        billing.query_purchases(BillingClient.ProductType.INAPP) # "inapp" atau "subs"

func _on_disconnected():
    print("BillingManager: Disconnected from Google Play Billing")
    billing_connected = false
    emit_signal("connection_status_changed", false)

func _on_connect_error(response_code, debug_message):
    print("BillingManager: Connect Error: %s - %s" % [response_code, debug_message])
    billing_connected = false
    emit_signal("connection_status_changed", false)

func query_products():
    if billing and billing_connected:
        billing.query_product_details(PRODUCTS, BillingClient.ProductType.INAPP)

func purchase(product_id: String):
    if billing and billing_connected:
        var response = billing.purchase(product_id)
        if response.status != OK:
            emit_signal("purchase_failed", "Purchase request failed: " + str(response.response_code))
    else:
        emit_signal("purchase_failed", "Billing service not connected")

# Callback saat detail produk diterima (harga, deskripsi, dll)
func _on_product_details_query_completed(response: Dictionary):
    if response.get("status") == OK:
        var product_details = response.get("product_details_list", []) # Adjust key based on plugin
        if product_details.is_empty() and response.has("product_details"): # Fallback check
            product_details = response.get("product_details")

        print("BillingManager: Product details received: ", product_details)
        emit_signal("product_details_received", product_details)
    else:
        print("BillingManager: Product query failed: ", response)

func _on_purchases_query_completed(response):
    if response is Dictionary and response.has("status") and response.get("status") == OK:
        var purchases = response.get("purchases_list", [])
        _on_purchases_updated({"status": OK, "purchases_list": purchases})
    elif response is Dictionary:
         print("BillingManager: Purchase query failed with status: ", response.get("status", "unknown"))
    else:
         print("BillingManager: Purchase query response is not a Dictionary: ", response)

func _on_purchases_updated(response: Dictionary):
    var status = response.get("status")
    if status == OK:
        var purchases = response.get("purchases_list", [])
        for purch in purchases:
            if purch.get("purchase_state") == 1: # 1 = PURCHASED
                _handle_purchase(purch)
    elif status == 1: # USER_CANCELED
        emit_signal("purchase_cancelled")
    else:
        _on_purchase_error(status, response.get("debug_message", "Unknown error"))

func _handle_purchase(purch):
    var products = purch.get("products", [])
    if products.is_empty():
        return

    var product_id = products[0] # Biasanya array, ambil yang pertama

    # Jika produk adalah consumable (bisa dibeli berkali-kali, misal koin), harus di-consume
    if "coin" in product_id:
        billing.consumePurchase(purch.get("purchase_token"))

    # Jika produk adalah non-consumable (sekali beli, misal remove ads), harus di-acknowledge
    if "remove_ads" in product_id and not purch.get("is_acknowledged"):
        billing.acknowledgePurchase(purch.get("purchase_token"))

    # Beritahu game logic bahwa pembelian sukses
    emit_signal("purchase_successful", product_id)

func _on_consume_purchase_response(response: Dictionary):
    if response.get("status") != OK:
        print("BillingManager: Consume failed: ", response)

func _on_acknowledge_purchase_response(response: Dictionary):
    if response.get("status") != OK:
        print("BillingManager: Acknowledge failed: ", response)

func _on_purchase_error(response_code, error_message):
    print("BillingManager: Purchase error: ", error_message)
    if response_code == 1: # USER_CANCELED
        emit_signal("purchase_cancelled")
    else:
        emit_signal("purchase_failed", error_message)
