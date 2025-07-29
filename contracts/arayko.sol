// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OnlineShop
 * @dev A basic smart contract for an online shopping platform.
 * This contract enables product listings, purchases, payment handling, and order tracking.
 */
contract OnlineShop {

    // Struct to define a product
    struct Product {
        uint id;            // Unique identifier for the product
        address payable seller; // The address of the seller (can receive Ether)
        string name;        // Name of the product
        uint price;         // Price of the product in Wei (smallest unit of Ether)
        uint stock;         // Available stock of the product
        bool listed;        // True if the product is actively listed
    }

    // Mapping from product ID to Product struct
    mapping(uint => Product) public products;
    // Mapping from buyer address to an array of product IDs they have purchased
    mapping(address => uint[]) public buyerOrders;

    // Counter for unique product IDs
    uint private nextProductId;

    // Event emitted when a new product is listed
    event ProductListed(
        uint indexed productId,
        address indexed seller,
        string name,
        uint price,
        uint stock
    );

    // Event emitted when a product is purchased
    event ProductPurchased(
        uint indexed productId,
        address indexed buyer,
        address indexed seller,
        uint pricePaid,
        uint quantityBought
    );

    /**
     * @dev Constructor: Initializes the next product ID.
     */
    constructor() {
        nextProductId = 1; // Start product IDs from 1
    }

    /**
     * @dev Allows a vendor to list a new product.
     * @param _name The name of the product.
     * @param _price The price of the product in Wei.
     * @param _stock The initial stock quantity of the product.
     */
    function addProduct(string memory _name, uint _price, uint _stock) public {
        // Ensure price and stock are valid
        require(_price > 0, "Product price must be greater than zero.");
        require(_stock > 0, "Product stock must be greater than zero.");

        // Get the next available product ID
        uint productId = nextProductId;
        // Create a new Product struct and store it in the mapping
        products[productId] = Product({
            id: productId,
            seller: payable(msg.sender), // The caller is the seller
            name: _name,
            price: _price,
            stock: _stock,
            listed: true
        });

        // Increment the product ID counter for the next product
        nextProductId++;

        // Emit an event to log the new product listing
        emit ProductListed(productId, msg.sender, _name, _price, _stock);
    }

    /**
     * @dev Allows a buyer to purchase a product.
     * The buyer must send the exact amount of Ether required for the purchase.
     * @param _productId The ID of the product to purchase.
     * @param _quantity The quantity of the product to purchase.
     */
    function purchaseProduct(uint _productId, uint _quantity) public payable {
        // Retrieve the product from the mapping
        Product storage product = products[_productId];

        // Validate product existence and listing status
        require(product.listed, "Product is not listed or does not exist.");
        // Validate sufficient stock
        require(product.stock >= _quantity, "Not enough stock available.");
        // Validate that the sent Ether matches the total price
        require(msg.value == product.price * _quantity, "Incorrect Ether amount sent.");
        // Prevent seller from buying their own product (optional, but good practice)
        require(msg.sender != product.seller, "Seller cannot purchase their own product.");

        // Deduct the purchased quantity from the product's stock
        product.stock -= _quantity;

        // Transfer the payment to the seller
        (bool success, ) = product.seller.call{value: msg.value}("");
        require(success, "Failed to send Ether to seller.");

        // Record the purchase for the buyer
        // For simplicity, we're just adding the product ID to the buyer's order history.
        // A more complex system might track quantity per order, timestamp, etc.
        for (uint i = 0; i < _quantity; i++) {
            buyerOrders[msg.sender].push(_productId);
        }

        // Emit an event to log the purchase
        emit ProductPurchased(_productId, msg.sender, product.seller, msg.value, _quantity);
    }

    /**
     * @dev Allows a seller to update the stock of their listed product.
     * @param _productId The ID of the product to update.
     * @param _newStock The new stock quantity.
     */
    function updateProductStock(uint _productId, uint _newStock) public {
        Product storage product = products[_productId];
        // Ensure the product exists and the caller is the seller of this product
        require(product.listed, "Product does not exist.");
        require(product.seller == msg.sender, "Only the seller can update this product's stock.");

        product.stock = _newStock;
    }

    /**
     * @dev Allows a seller to delist their product.
     * @param _productId The ID of the product to delist.
     */
    function delistProduct(uint _productId) public {
        Product storage product = products[_productId];
        // Ensure the product exists and the caller is the seller of this product
        require(product.listed, "Product does not exist or is already delisted.");
        require(product.seller == msg.sender, "Only the seller can delist this product.");

        product.listed = false; // Mark the product as not listed
    }

    /**
     * @dev Fallback function to handle direct Ether payments to the contract.
     * Reverts if Ether is sent without calling a specific function.
     */
    receive() external payable {
        revert("Direct Ether payments not allowed. Use purchaseProduct function.");
    }
}
