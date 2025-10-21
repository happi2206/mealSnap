////
////  MealEntry.swift
////  mealSnap
////
////  Created by Maher Parkar on 21/10/2025.
////
//
//
////
////  MealEntry.swift
////  mealSnap
////
////  Created by Farhan Khan on 20/10/2025.
////
//
//import Foundation
//import FirebaseFirestore
//
///// Represents a logged meal containing multiple detected food items.
//struct MealEntry: Identifiable, Codable {
//    @DocumentID var id: String?
//    var photoURL: String? // URL of meal photo in Firebase Storage
//    var date: Date
//    var foods: [FoodItem]
//    
//    /// Computed total calories for this meal
//    var totalCalories: Double {
//        foods.reduce(0) { $0 + $1.calories }
//    }
//    
//    var totalProtein: Double {
//        foods.reduce(0) { $0 + $1.protein }
//    }
//    
//    var totalCarbs: Double {
//        foods.reduce(0) { $0 + $1.carbs }
//    }
//    
//    var totalFat: Double {
//        foods.reduce(0) { $0 + $1.fat }
//    }
//    
//    init(id: String? = nil,
//         photoURL: String? = nil,
//         date: Date = Date(),
//         foods: [FoodItem]) {
//        self.id = id
//        self.photoURL = photoURL
//        self.date = date
//        self.foods = foods
//    }
//}
