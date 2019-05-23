pragma solidity ^0.5.0;

contract SupplyChain {
  address public owner;
  uint public skuCount;
  mapping(uint => Item) public items; // Maps the SKU (a number) to an Item.
  enum State { ForSale, Sold, Shipped, Received }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller; // "payable" as this address will be handling value transfer
    address payable buyer; // "payable" as this address will be handling value transfer
  }

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  modifier isOwner () { // Checks if the msg.sender is the owner of the contract
    require(owner == msg.sender, "Only contract owner can call this");
    _;
  }

  modifier verifyCaller (address _address) { // Verify if caller is a buyer or seller
    require (msg.sender == _address, "Incorrect caller");
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price, "Insufficient funds");
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint sku) {
    require(items[sku].state == State.ForSale, "Item not for sale");
    _;
  }

  modifier sold(uint sku) {
    require(items[sku].state == State.Sold, "Item not sold");
    _;
  }

  modifier shipped(uint sku) {
    require(items[sku].state == State.Shipped, "Item has not shipped");
    _;
  }

  modifier received(uint sku) {
    require(items[sku].state == State.Received, "Item has not been receieved");
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns(bool) {
    emit LogForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  // Check if the item is for sale, if the buyer paid enough, and check the value after the function
  // is called to make sure the buyer is refunded any excess ether sent.
  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku) {
    emit LogSold(_sku);
    items[_sku].seller.transfer(items[_sku].price); // Transfer money to the seller
    items[_sku].buyer = msg.sender; // Set the buyer as the person who called this transaction
    items[_sku].state = State.Sold; // Set the state to Sold.
  }

  // Check if the item is sold already, and that the person calling this function is the seller.
  function shipItem(uint _sku) public sold(_sku) verifyCaller(items[_sku].seller) {
    emit LogShipped(_sku);
    items[_sku].state = State.Shipped; // Change the state of the item to shipped.
  }

  // Check if the item is shipped already, and that the person calling this function is the buyer.
  function receiveItem(uint _sku) public shipped(_sku) verifyCaller(items[_sku].buyer) {
    emit LogReceived(_sku);
    items[_sku].state = State.Received; // Change the state of the item to received.
  }

  /* We have these functions completed so we can run tests, just ignore it :) */
  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}