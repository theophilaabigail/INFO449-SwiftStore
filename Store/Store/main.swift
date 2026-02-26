//
//  main.swift
//  Store
//
//  Created by Ted Neward on 2/29/24.
//

import Foundation

protocol SKU {
    var name: String { get }
    func price() -> Int
}

protocol Taxable {
    func tax() -> Int
}

protocol PricingScheme {
    func apply(to items: [SKU]) -> Int
}

class Item: SKU {
    var name: String
    var priceEach: Int
    
    init(name: String, priceEach: Int) {
        self.name = name
        self.priceEach = priceEach
    }
    
    func price() -> Int {
        return priceEach
    }
}

class TaxableItem: Item, Taxable {
    let taxRate: Double = 0.10
    
    func tax() -> Int {
        return Int((Double(priceEach) * taxRate).rounded(.up))
    }
}

class WeightedItem: SKU {
    var name: String
    var pricePerPound: Int
    var weight: Double
    
    init(name: String, pricePerPound: Int, weight: Double) {
        self.name = name
        self.pricePerPound = pricePerPound
        self.weight = weight
    }
    
    func price() -> Int {
        return Int((Double(pricePerPound) * weight).rounded())
    }
}

class TaxableWeightedItem: WeightedItem, Taxable {
    let taxRate: Double = 0.10
    
    func tax() -> Int {
        return Int((Double(price()) * taxRate).rounded(.up))
    }
}

class Coupon: SKU {
    var name: String
    var itemName: String
    var discountRate: Double
    
    init(itemName: String, discountRate: Double = 0.15) {
        self.name = "Coupon"
        self.itemName = itemName
        self.discountRate = discountRate
    }
    
    func price() -> Int {
        return 0
    }
}

class RainCheck: SKU {
    var name: String
    var itemName: String
    var specialPrice: Int
    var quantity: Int
    var weight: Double?
    
    init(itemName: String, specialPrice: Int, quantity: Int = 1, weight: Double? = nil) {
        self.name = "Rain Check"
        self.itemName = itemName
        self.specialPrice = specialPrice
        self.quantity = quantity
        self.weight = weight
    }
    
    func price() -> Int {
        return 0
    }
}

class BuyTwoGetOneFree: PricingScheme {
    var itemName: String
    
    init(itemName: String) {
        self.itemName = itemName
    }
    
    func apply(to items: [SKU]) -> Int {
        let matchingItems = items.filter { $0.name == itemName }
        let count = matchingItems.count
        let freeItems = count / 3
        let discount = freeItems * (matchingItems.first?.price() ?? 0)
        return discount
    }
}

class GroupedDiscount: PricingScheme {
    var item1Pattern: String
    var item2Pattern: String
    var discountRate: Double
    
    init(item1Pattern: String, item2Pattern: String, discountRate: Double = 0.10) {
        self.item1Pattern = item1Pattern
        self.item2Pattern = item2Pattern
        self.discountRate = discountRate
    }
    
    func apply(to items: [SKU]) -> Int {
        let group1Items = items.filter { $0.name.localizedCaseInsensitiveContains(item1Pattern) }
        let group2Items = items.filter { $0.name.localizedCaseInsensitiveContains(item2Pattern) }
        
        let pairs = min(group1Items.count, group2Items.count)
        var discount = 0
        
        for i in 0..<pairs {
            discount += Int(Double(group1Items[i].price()) * discountRate)
            discount += Int(Double(group2Items[i].price()) * discountRate)
        }
        
        return discount
    }
}

class Receipt {
    private var skus: [SKU] = []
    private var pricingSchemes: [PricingScheme] = []
    
    func add(_ sku: SKU) {
        skus.append(sku)
    }
    
    func items() -> [SKU] {
        return skus
    }
    
    func addPricingScheme(_ scheme: PricingScheme) {
        pricingSchemes.append(scheme)
    }
    
    private func calculateSubtotal() -> Int {
        let regularItems = skus.filter { !($0 is Coupon) && !($0 is RainCheck) }
        return regularItems.reduce(0) { $0 + $1.price() }
    }
    
    private func calculateDiscounts() -> Int {
        var totalDiscount = 0
        
        for scheme in pricingSchemes {
            totalDiscount += scheme.apply(to: skus)
        }
        
        let coupons = skus.compactMap { $0 as? Coupon }
        for coupon in coupons {
            if let item = skus.first(where: { $0.name == coupon.itemName && !($0 is Coupon) }) {
                totalDiscount += Int(Double(item.price()) * coupon.discountRate)
            }
        }
        
        return totalDiscount
    }
    
    private func applyRainChecks() -> [SKU] {
        var modifiedItems = skus.filter { !($0 is RainCheck) && !($0 is Coupon) }
        let rainChecks = skus.compactMap { $0 as? RainCheck }
        
        for rainCheck in rainChecks {
            for i in 0..<modifiedItems.count {
                if modifiedItems[i].name == rainCheck.itemName {
                    if let weightedItem = modifiedItems[i] as? WeightedItem, let weight = rainCheck.weight {
                        modifiedItems[i] = WeightedItem(name: weightedItem.name, pricePerPound: rainCheck.specialPrice, weight: weight)
                    } else if let item = modifiedItems[i] as? Item {
                        modifiedItems[i] = Item(name: item.name, priceEach: rainCheck.specialPrice)
                    }
                    break
                }
            }
        }
        
        return modifiedItems
    }
    
    private func calculateTax() -> Int {
        let modifiedItems = applyRainChecks()
        let taxableItems = modifiedItems.compactMap { $0 as? Taxable }
        return taxableItems.reduce(0) { $0 + $1.tax() }
    }
    
    func total() -> Int {
        let modifiedItems = applyRainChecks()
        let subtotal = modifiedItems.reduce(0) { $0 + $1.price() }
        let discounts = calculateDiscounts()
        let tax = calculateTax()
        return subtotal - discounts + tax
    }
    
    func output() -> String {
        var result = "Receipt:\n"
        let displayItems = skus.filter { !($0 is Coupon) && !($0 is RainCheck) }
        
        for sku in displayItems {
            let dollars = sku.price() / 100
            let cents = sku.price() % 100
            result += "\(sku.name): $\(dollars).\(String(format: "%02d", cents))\n"
        }
        
        result += "------------------\n"
        
        let tax = calculateTax()
        if tax > 0 {
            let taxDollars = tax / 100
            let taxCents = tax % 100
            result += "Tax: $\(taxDollars).\(String(format: "%02d", taxCents))\n"
        }
        
        let totalPrice = total()
        let totalDollars = totalPrice / 100
        let totalCents = totalPrice % 100
        result += "TOTAL: $\(totalDollars).\(String(format: "%02d", totalCents))"
        return result
    }
    
    func clear() {
        skus.removeAll()
    }
}

class Register {
    private var receipt: Receipt
    private var pricingSchemes: [PricingScheme] = []
    
    init() {
        self.receipt = Receipt()
        applyPricingSchemesToReceipt()
    }
    
    func scan(_ sku: SKU) {
        receipt.add(sku)
    }
    
    func addPricingScheme(_ scheme: PricingScheme) {
        pricingSchemes.append(scheme)
        receipt.addPricingScheme(scheme)
    }
    
    private func applyPricingSchemesToReceipt() {
        for scheme in pricingSchemes {
            receipt.addPricingScheme(scheme)
        }
    }
    
    func subtotal() -> Int {
        return receipt.total()
    }
    
    func total() -> Receipt {
        let currentReceipt = receipt
        receipt = Receipt()
        applyPricingSchemesToReceipt()
        return currentReceipt
    }
}

class Store {
    let version = "0.1"
    func helloWorld() -> String {
        return "Hello world"
    }
}

