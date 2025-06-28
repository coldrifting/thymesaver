//
//  thymesaverTests.swift
//  thymesaverTests
//
//  Created by Aiden Van Dyke on 6/11/25.
//

import Testing
@testable import ThymeSaver

struct ThymeSaverTests {

    @Test func addFourthsFrac() async throws {
        let f1 = Fraction(1, dem: 4)
        let f2 = Fraction(1, dem: 4)
        
        let fResult1 = f1 + f2
        let fResult2 = f2 + f1
        
        let eResult = Fraction(1, dem: 2)
        
        #expect(fResult1 == eResult)
        #expect(fResult2 == eResult)
    }
    
    @Test func addFourths() async throws {
        let a1 = Amount(Fraction(1, dem: 4), type: UnitType.volumeTeaspoons)
        let a2 = Amount(Fraction(1, dem: 4), type: UnitType.volumeTeaspoons)
        
        let aResult1 = a1 + a2
        let aResult2 = a2 + a1
        
        let eResult = Amount(Fraction(1, dem: 2), type: UnitType.volumeTeaspoons)
        
        #expect(aResult1 == eResult)
        #expect(aResult2 == eResult)
    }
    
    @Test func addTeaspoonstoTablespoon() async throws {
        let a1 = Amount(Fraction(1), type: UnitType.volumeTeaspoons)
        let a2 = Amount(Fraction(2), type: UnitType.volumeTeaspoons)
        
        let aResult1 = a1 + a2
        let aResult2 = a2 + a1
        
        let eResult = Amount(Fraction(1), type: UnitType.volumeTablespoons)
        
        #expect(aResult1 == eResult)
        #expect(aResult2 == eResult)
    }
    
    @Test func addCupAndOuncesToOunces() async throws {
        let a1 = Amount(Fraction(8), type: UnitType.volumeOunces)
        let a2 = Amount(Fraction(1), type: UnitType.volumeCups)
        
        let aResult1 = a1 + a2
        let aResult2 = a2 + a1
        
        let eResult = Amount(Fraction(2), type: UnitType.volumeCups)
        
        #expect(aResult1 == eResult)
        #expect(aResult2 == eResult)
    }

    @Test func testCombine() async throws {
        let a1 = Item(
            itemId: 181,
            itemName: "Monterey Jack Cheese",
            itemTemp: .chilled,
            defaultUnits: .volumeCups,
            cartAmount: Amount(2, type: .volumeCups))
        
        let a2 = Item(
            itemId: 181,
            itemName: "Monterey Jack Cheese",
            itemTemp: .chilled,
            defaultUnits: .volumeCups,
            cartAmount: Amount(1, type: .volumeCups))
        
        let a3 = Item(
            itemId: 181,
            itemName: "Monterey Jack Cheese",
            itemTemp: .chilled,
            defaultUnits: .volumeCups,
            cartAmount: Amount(1, type: .volumeCups))
        
        let itemsCombined = CartAisle.combine(items: [a1, a2])
        
        #expect(itemsCombined.count == 1)
        #expect(itemsCombined.first?.cartAmount == Amount(3, type: .volumeCups))
        
        let itemsCombined2 = CartAisle.combine(items: [a1, a2, a3])
        
        #expect(itemsCombined2.count == 1)
        #expect(itemsCombined2.first?.cartAmount == Amount(4, type: .volumeCups))
    }
    
    @Test func testCombineSimplifies() async throws {
        let a1 = Item(
            itemId: 89,
            itemName: "Salt",
            itemTemp: .ambient,
            defaultUnits: .volumeTeaspoons,
            cartAmount: Amount(Fraction(1, dem: 4), type: .volumeTeaspoons))
        
        let a2 = Item(
            itemId: 89,
            itemName: "Salt",
            itemTemp: .ambient,
            defaultUnits: .volumeTeaspoons,
            cartAmount: Amount(Fraction(1, dem: 4), type: .volumeTeaspoons))
        
        let itemsCombined = CartAisle.combine(items: [a1, a2])
        
        #expect(itemsCombined.count == 1)
        #expect(itemsCombined.first?.cartAmount == Amount(Fraction(1,dem:2), type: .volumeTeaspoons))
    }
}
