import GRDB

struct PrepRecipeInfo: FetchableRecord, Identifiable {
    var prepId: Int
    var recipes: String
    
    var id: Int { prepId }
    
    init(row: GRDB.Row) throws {
        prepId = row["prepId"]
        recipes = row["recipes"]
    }
    
    static func getRecipesUsingPrep() -> SQLRequest<PrepRecipeInfo> {
        """
        SELECT 
            Preps.prepId,
            GROUP_CONCAT(Recipes.recipeName, '|') AS recipes
        FROM Recipes
        NATURAL JOIN RecipeEntries
        NATURAL JOIN Preps
        GROUP BY Preps.prepId
        ORDER BY Preps.prepId, LOWER(Recipes.recipeName);
        """
    }
}
