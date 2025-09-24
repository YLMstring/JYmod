if DrawStrBoxYesNo(-1, -1, "要挑战吗？", C_ORANGE, CC.DefaultFont) then
	WarMain(289)
	JY.Base["人X1"] = 11
	JY.Base["人Y1"] = 44
	light()
	instruct_3(25, 72, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, -2)
	instruct_3(25, 101, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2, -2)
	null(-2, -2)
end
do return end  --无条件结束事件