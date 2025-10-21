////
////  FoodItem.swift
////  mealSnap
////
////  Created by Maher Parkar on 21/10/2025.
////
//
//
//import Foundation
//import FirebaseFirestore
//
//
///// Represents an individual food item detected in a meal
//struct FoodItem: Identifiable, Codable, Hashable {
//    @DocumentID var id: String?
//    var name: String
//    var calories: Double
//    var protein: Double
//    var carbs: Double
//    var fat: Double
//    var servingSize: Double? // e.g. grams
//    var dateAdded: Date = Date()
//    
//    init(id: String? = nil,
//         name: String,
//         calories: Double,
//         protein: Double,
//         carbs: Double,
//         fat: Double,
//         servingSize: Double? = nil) {
//        self.id = id
//        self.name = name
//        self.calories = calories
//        self.protein = protein
//        self.carbs = carbs
//        self.fat = fat
//        self.servingSize = servingSize
//    }
//}
