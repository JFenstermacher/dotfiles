rex.action({
	name = "test_ui_pick",
	title = "Test UI Pick…",
	run = function()
		return rex.ui.pick({
			title = "Test Picker",
			placeholder = "Type to filter…",
			items = {
				{ id = "alpha", label = "Alpha", detail = "First test item" },
				{ id = "beta", label = "Beta", detail = "Second test item" },
				{ id = "gamma", label = "Gamma", detail = "Third test item" },
			},
		})
	end,
})
