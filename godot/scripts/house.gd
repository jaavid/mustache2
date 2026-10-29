extends RefCounted
# Geometry ported from the playable Canvas version; world coordinates stay unchanged.
const WALLS = [
	{"x": 73, "y": 73, "w": 1370, "h": 22},
	{"x": 73, "y": 932, "w": 1370, "h": 22},
	{"x": 73, "y": 73, "w": 22, "h": 880},
	{"x": 1421, "y": 73, "w": 22, "h": 880},
	{"x": 516, "y": 82, "w": 23, "h": 250},
	{"x": 516, "y": 434, "w": 23, "h": 265},
	{"x": 516, "y": 807, "w": 23, "h": 136},
	{"x": 991, "y": 82, "w": 23, "h": 192},
	{"x": 991, "y": 378, "w": 23, "h": 246},
	{"x": 991, "y": 715, "w": 23, "h": 228},
	{"x": 82, "y": 517, "w": 196, "h": 23},
	{"x": 395, "y": 517, "w": 301, "h": 23},
	{"x": 847, "y": 517, "w": 290, "h": 23},
	{"x": 1257, "y": 517, "w": 170, "h": 23}
]
const FURNITURE = [
	{"x": 143, "y": 205, "w": 135, "h": 70, "type": "sofa", "label": "SOFA", "color": "#9276ba"},
	{"x": 383, "y": 144, "w": 68, "h": 98, "type": "closet", "label": "CLOSET", "color": "#b17858"},
	{"x": 317, "y": 369, "w": 102, "h": 64, "type": "table", "label": "TABLE", "color": "#b98c63"},
	{"x": 650, "y": 193, "w": 114, "h": 75, "type": "bed", "label": "BED", "color": "#809bc8"},
	{"x": 825, "y": 367, "w": 104, "h": 69, "type": "desk", "label": "DESK", "color": "#b6a076"},
	{
		"x": 1129,
		"y": 175,
		"w": 158,
		"h": 83,
		"type": "table",
		"label": "DINING",
		"color": "#b89063"
	},
	{"x": 1286, "y": 356, "w": 83, "h": 73, "type": "closet", "label": "SHELF", "color": "#a4795b"},
	{"x": 176, "y": 693, "w": 140, "h": 81, "type": "sofa", "label": "SOFA", "color": "#75a19a"},
	{"x": 357, "y": 821, "w": 93, "h": 61, "type": "table", "label": "TABLE", "color": "#ad7d6a"},
	{"x": 653, "y": 690, "w": 131, "h": 80, "type": "bed", "label": "BED", "color": "#ba89a6"},
	{"x": 854, "y": 830, "w": 91, "h": 71, "type": "closet", "label": "SHELF", "color": "#8e6a4f"},
	{"x": 1110, "y": 682, "w": 145, "h": 75, "type": "sofa", "label": "SOFA", "color": "#ba9179"},
	{"x": 1323, "y": 830, "w": 72, "h": 69, "type": "desk", "label": "DESK", "color": "#a7856a"}
]
const SPOTS = [
	{"x": 384, "y": 299, "name": "کمد اتاق نشیمن", "cover": "closet"},
	{"x": 735, "y": 337, "name": "تخت اتاق خواب", "cover": "bed"},
	{"x": 1225, "y": 319, "name": "میز آشپزخانه", "cover": "table"},
	{"x": 261, "y": 835, "name": "مبل پذیرایی", "cover": "sofa"},
	{"x": 881, "y": 792, "name": "کتابخانه", "cover": "closet"},
	{"x": 1264, "y": 834, "name": "صندلی اتاق", "cover": "desk"},
	{"x": 367, "y": 459, "name": "زیر میز نشیمن", "cover": "table"},
	{"x": 1217, "y": 288, "name": "زیر میز آشپزخانه", "cover": "table"},
	{"x": 397, "y": 902, "name": "زیر میز پذیرایی", "cover": "table"}
]
const ROOMS = [
	{"x": 95, "y": 95, "w": 421, "h": 422, "name": "اتاق نشیمن", "c": "#393c58"},
	{"x": 539, "y": 95, "w": 452, "h": 422, "name": "اتاق خواب", "c": "#3d465d"},
	{"x": 1014, "y": 95, "w": 407, "h": 422, "name": "آشپزخانه", "c": "#454251"},
	{"x": 95, "y": 540, "w": 421, "h": 392, "name": "پذیرایی", "c": "#405157"},
	{"x": 539, "y": 540, "w": 452, "h": 392, "name": "اتاق مطالعه", "c": "#453c54"},
	{"x": 1014, "y": 540, "w": 407, "h": 392, "name": "انباری", "c": "#484453"}
]
