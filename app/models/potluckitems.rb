class Potluckitems
	attr_reader :potluck_hash

	def initialize
		@potluck_hash = {"apps" => ["Six Layer Dip","Quacamole","Salsa","Tortilla Chips","Jumbo Shrimp Cocktail","Artichoke Dip","Mexican Cheese Dip","Chili Cheese Dip","Hummus","Bite-sized Pizzas","Mac and Cheese Bites","Ahi Tuna Poke","Loaded Jalapeno Poppers","Stuffed Mushrooms","Fried Mozzarella Sticks","Beef Taquitos","Spring Rolls","Egg Rolls","Loaded Nachos","Caprese Toasts","Pigs in a Blanket","Veggie Platter","Pulled Pork Sliders","Buffalo Wings","Chicken Tenders"],"salads" => ["Rainbow Stacked Salad","Potato Salad","Cole Slaw","Pasta Salad","Taco Potato Salad","Fruit Salad"], "main dishes" => ["Make Ahead Fajitas","Pork Ribs","Beef Ribs","Tri Tip","Hot Dogs","Burgers","Kebabs","Thai Chicken Satay","Crunchy Macaroni and Cheese","Spanish Chicken","BLT Rollups","Meatballs","Spaghetti","Pizza","Chicken Chow Mein","Honey Walnut Shrimp","Smoked Salmon","Spanish Chicken","Sicilian One Pot","Honey-baked Ham","Sandwich Platter","Stir Fry","Beef Stroganoff","Meatloaf"], "sides" => ["Scalloped Potatoes","Baked Stuffed Peppers","French Fries","Baked Beans","Popcorn Chicken","Mashed Potatoes w/Gravy","Potato Wedges","Garlic Mashed Potatoes","Sweet Potatoes / Sweet Potato Fries","Kimchi","Garlic Bread"], "desserts" => ["Cobbler","Key Lime Pie","Brownies","Turtle Pie","Cupcakes","Cookies","Pumpkin Pie","Apple Pie","Chocolate Mousse","Block Party Ice Cream Cake","Parfaits","Mini Muffins","Bar Cookies","Cheesecake","Candy","Bread Pudding","Jello","Chocolate Pudding","Eclairs","Cannoli","Funnel Cakes","Fruit Pinwheels","Strudels","Fruit Tart","Dessert Crepes","Scones"] }

	end

	def return_items
		return @potluck_hash
	end
end