//
//  StoreTests.swift
//  StoreTests
//
//  Created by Ted Neward on 2/29/24.
//

import XCTest

final class StoreTests: XCTestCase {

    var register = Register()

    override func setUpWithError() throws {
        register = Register()
    }

    override func tearDownWithError() throws { }

    func testBaseline() throws {
        XCTAssertEqual("0.1", Store().version)
        XCTAssertEqual("Hello world", Store().helloWorld())
    }
    
    func testOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(199, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
------------------
TOTAL: $1.99
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testThreeSameItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 3, register.subtotal())
    }
    
    func testThreeDifferentItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        register.scan(Item(name: "Pencil", priceEach: 99))
        XCTAssertEqual(298, register.subtotal())
        register.scan(Item(name: "Granols Bars (Box, 8ct)", priceEach: 499))
        XCTAssertEqual(797, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(797, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
Pencil: $0.99
Granols Bars (Box, 8ct): $4.99
------------------
TOTAL: $7.97
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testBuyTwoGetOneFree() {
        register.addPricingScheme(BuyTwoGetOneFree(itemName: "Beans (8oz Can)"))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 2, register.subtotal())
    }
    
    func testBuyTwoGetOneFreeMultipleSets() {
        register.addPricingScheme(BuyTwoGetOneFree(itemName: "Beans (8oz Can)"))
        for _ in 0..<6 {
            register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        }
        XCTAssertEqual(199 * 4, register.subtotal())
    }
    
    func testBuyTwoGetOneFreeNotEnoughItems() {
        register.addPricingScheme(BuyTwoGetOneFree(itemName: "Beans (8oz Can)"))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 2, register.subtotal())
    }
    
    func testGroupedDiscount() {
        register.addPricingScheme(GroupedDiscount(item1Pattern: "Ketchup", item2Pattern: "Beer"))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        register.scan(Item(name: "Beer", priceEach: 599))
        XCTAssertEqual(299 + 599 - 29 - 59, register.subtotal())
    }
    
    func testGroupedDiscountMultiplePairs() {
        register.addPricingScheme(GroupedDiscount(item1Pattern: "Ketchup", item2Pattern: "Beer"))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        register.scan(Item(name: "Beer", priceEach: 599))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        register.scan(Item(name: "Beer", priceEach: 599))
        XCTAssertEqual((299 + 599) * 2 - (29 + 59) * 2, register.subtotal())
    }
    
    func testGroupedDiscountUnevenPairs() {
        register.addPricingScheme(GroupedDiscount(item1Pattern: "Ketchup", item2Pattern: "Beer"))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        register.scan(Item(name: "Beer", priceEach: 599))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        XCTAssertEqual(299 * 2 + 599 - 29 - 59, register.subtotal())
    }
    
    func testWeightedItem() {
        register.scan(WeightedItem(name: "Steak", pricePerPound: 899, weight: 1.1))
        XCTAssertEqual(989, register.subtotal())
    }
    
    func testWeightedItemDifferentWeights() {
        register.scan(WeightedItem(name: "Apples", pricePerPound: 299, weight: 2.5))
        register.scan(WeightedItem(name: "Bananas", pricePerPound: 199, weight: 1.0))
        XCTAssertEqual(748 + 199, register.subtotal())
    }
    
    func testCoupon() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Coupon(itemName: "Beans (8oz Can)"))
        XCTAssertEqual(199 - 29, register.subtotal())
    }
    
    func testCouponOnlyAppliesToOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Coupon(itemName: "Beans (8oz Can)"))
        XCTAssertEqual(199 * 2 - 29, register.subtotal())
    }
    
    func testCouponNoMatchingItem() {
        register.scan(Item(name: "Pencil", priceEach: 99))
        register.scan(Coupon(itemName: "Beans (8oz Can)"))
        XCTAssertEqual(99, register.subtotal())
    }
    
    func testRainCheck() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(RainCheck(itemName: "Beans (8oz Can)", specialPrice: 99))
        XCTAssertEqual(99, register.subtotal())
    }
    
    func testRainCheckNoEffect() {
        register.scan(Item(name: "Pencil", priceEach: 99))
        register.scan(RainCheck(itemName: "Beans (8oz Can)", specialPrice: 50))
        XCTAssertEqual(99, register.subtotal())
    }
    
    func testRainCheckOnlyAffectsOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(RainCheck(itemName: "Beans (8oz Can)", specialPrice: 99))
        XCTAssertEqual(99 + 199, register.subtotal())
    }
    
    func testRainCheckWithWeightedItem() {
        register.scan(WeightedItem(name: "Steak", pricePerPound: 899, weight: 1.1))
        register.scan(RainCheck(itemName: "Steak", specialPrice: 699, weight: 1.1))
        XCTAssertEqual(769, register.subtotal())
    }
    
    func testTaxOnNonEdibleItem() {
        register.scan(TaxableItem(name: "Pencil", priceEach: 99))
        XCTAssertEqual(99 + 10, register.subtotal())
    }
    
    func testTaxOnMultipleItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(TaxableItem(name: "Pencil", priceEach: 99))
        XCTAssertEqual(199 + 99 + 10, register.subtotal())
    }
    
    func testTaxRoundingUp() {
        register.scan(TaxableItem(name: "Item", priceEach: 95))
        XCTAssertEqual(95 + 10, register.subtotal())
    }
    
    func testTaxWithWeightedItem() {
        register.scan(TaxableWeightedItem(name: "Light Bulb", pricePerPound: 1000, weight: 0.5))
        XCTAssertEqual(500 + 50, register.subtotal())
    }
    
    func testComplexScenario() {
        register.addPricingScheme(BuyTwoGetOneFree(itemName: "Beans (8oz Can)"))
        register.addPricingScheme(GroupedDiscount(item1Pattern: "Ketchup", item2Pattern: "Beer"))
        
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Ketchup", priceEach: 299))
        register.scan(Item(name: "Beer", priceEach: 599))
        register.scan(TaxableItem(name: "Pencil", priceEach: 99))
        register.scan(Coupon(itemName: "Ketchup"))
        register.scan(WeightedItem(name: "Apples", pricePerPound: 299, weight: 2.0))
        
        let subtotalWithoutTax = (199 * 2) + (299 - 29 - 44) + (599 - 59) + 99 + 598
        let tax = 10
        XCTAssertEqual(subtotalWithoutTax + tax, register.subtotal())
    }
}
