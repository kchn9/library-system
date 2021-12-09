// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Library
 * @dev Implements library book management system.
 */
contract Library {
    mapping(string => uint64) private allISBN;
    mapping(uint64 => Book) public books;
    mapping(address => uint64[]) public register;
    address private librarian;
    
    // enum stores internal state to describe book availability
    enum BookState { Borrowed, Available }
    struct Book {
        string title;
        uint16 releaseYear;
        uint8 amount;
        BookState state;
        uint64 ISBN;
    }

    /**
     * @dev librarianOnly modifier allow to control access to addBook funtion
     */
    modifier librarianOnly() {
        // msg.sender - account / address who calls contract
        require(msg.sender == librarian);
        // if require fails it reverts
        _;
        // placeholder for function
    }

    /**
     * @dev Create new Library instance and save librarian address
     */
    constructor() {
        librarian = msg.sender;
    }

    /**
     * @dev Adds new book record to database
     * @param _title title of book
     * @param _releaseYear release year of book
     * @param _amount quantity of available books, must be greater than 0
     * @param _ISBN international serial book number used to indetify book
     */
    function addBook(string memory _title, uint16 _releaseYear, uint8 _amount, uint64 _ISBN) 
        public 
        librarianOnly
    {
        if (_amount <= 1) revert ("Book quantity less than 1. Unable to add record");

        books[_ISBN] = Book(_title, _releaseYear, _amount, BookState.Available, _ISBN);
        allISBN[_title] = _ISBN;
    }
    
    /**
     * @dev Assign book to user address, decrease quantity of available books, mark them as borrowed if quantity < 1
     * @param _title title of book to borrow
     */
    function borrowBook(string memory _title) public {
        (bool isAvailable, uint64 ISBN) = checkAvailability(_title);
        (bool isDuplicate, ) = checkDuplicate(ISBN);

        if (isAvailable && !isDuplicate) {
            books[ISBN].amount--;
            if (books[ISBN].amount == 0) books[ISBN].state = BookState.Borrowed;
            register[msg.sender].push(ISBN);
        } else if (!isAvailable) {
            revert("Book is not available now");
        } else if (isDuplicate) {
            revert("You already borrowed this book");
        } else {
            revert("Something gone wrong");
        }
    }

    /**
     * @dev Increase quantity in database, mark as available and delete record in user address
     * @param _title title of book to return
     */
    function returnBook(string memory _title) public {
        uint64 returnISBN = allISBN[_title];
        (bool isRequestValid, uint idx) = checkDuplicate(returnISBN);
        // if user have a book
        if (isRequestValid) {
            books[returnISBN].amount++;
            books[returnISBN].state = BookState.Available;
            return delete register[msg.sender][idx];
        }
        revert("You dont have this book");
    }

    // HELPER FUNCTIONS

    /**
     * @dev Checks that the book is supported by the system, makes sure that the correct book is selected
     * @dev and finds the ISBN of the book
     * @param _title book's _title
     * @return bool describing availability
     * @return uint64 book's ISBN
     */
    function checkAvailability(string memory _title) internal view returns(bool, uint64) {
        if (contains(_title)) {
            uint64 ISBN = allISBN[_title];
            Book memory book = books[ISBN];
            // the simplest way to compare strings 
            if (keccak256(bytes(book.title)) == keccak256(bytes(_title)) &&
                book.state == BookState.Available && book.amount >= 1) {
                    return (true, ISBN);
                }
        }
        return (false, 0);
    }

    /**
     * @dev Checks that book is in database
     * @param _title book's _title
     * @return bool describing if the book has been found
     */
    function contains(string memory _title) internal view returns(bool) {
        return allISBN[_title] != 0;
    }

    /**
     * @dev Checks that user already have a book borrowed and finds index of book in register if so
     * @param _ISBN book's _ISBN
     * @return bool describing if user has borrowed the book
     * @return index of book in uint64[] register array
     */
    function checkDuplicate(uint64 _ISBN) internal view returns(bool, uint) {
        uint len = register[msg.sender].length;
        for (uint i = 0; i < len; i++) {
            if (register[msg.sender][i] == _ISBN) return (true, i);
        }
        return (false, 0);
    }
}
