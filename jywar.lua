function Set_Eff_Text(id, txwz, str)
	if WAR.Person[id][txwz] ~= nil then
		WAR.Person[id][txwz] = WAR.Person[id][txwz].."+"..str
	else
		WAR.Person[id][txwz] = str
	end
end

--返回两人之间的实际距离
function War_realjl(ida, idb)
	if ida == nil then
		ida = WAR.CurID
	end
	CleanWarMap(3, 255)
	local x = WAR.Person[ida]["坐标X"]
	local y = WAR.Person[ida]["坐标Y"]
	local steparray = {}
	steparray[0] = {}
	steparray[0].bushu = {}
	steparray[0].x = {}
	steparray[0].y = {}
	SetWarMap(x, y, 3, 0)
	steparray[0].num = 1
	steparray[0].bushu[1] = 0		--还能移动的步数
	steparray[0].x[1] = x
	steparray[0].y[1] = y
	return War_FindNextStep1(steparray, 0, ida, idb)
end

--AI选择目标的函数
function AIThink(kfid)
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local kungfuid = JY.Person[pid]["武功" .. kfid]
	local atkarray = {}
	local num = 0
	CleanWarMap(4, -1)
	local movearray = War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
	WarDrawMap(1)
	ShowScreen()

	for i = 0, WAR.Person[WAR.CurID]["移动步数"] do
		local step_num = movearray[i].num
		if step_num ~= nil then
			for j = 1, step_num do
				local xx = movearray[i].x[j]
				local yy = movearray[i].y[j]
				num = num + 1
				atkarray[num] = {}
				atkarray[num].x, atkarray[num].y = xx, yy
				atkarray[num].p, atkarray[num].ax, atkarray[num].ay = GetAtkNum(xx, yy, WAR.CurID, kungfuid)
			end
		end
	end

	for i = 1, num - 1 do
		for j = i + 1, num do
			if atkarray[i].p < atkarray[j].p then
				atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
			end
		end
	end
	--lib.Debug(JY.Person[pid]["姓名"])
	--lib.Debug(atkarray[1].p)
	if atkarray[1].p > 0 then
		for i = 2, num do
			if atkarray[i].p == 0 or atkarray[i].p < atkarray[1].p / 2 then
				num = i - 1
				break;
			end
		end
		for i = 1, num do
			if WAR.Person[WAR.CurID]["我方"] == true then
				--flag: approach enemies.
				atkarray[i].p = atkarray[i].p + GetMovePoint(atkarray[i].x, atkarray[i].y) / 10000
			else
				--flag: aviod enemies. avoiding as many enemies as possible while retaining targeting the spot with higher threat
				atkarray[i].p = atkarray[i].p + GetMovePoint(atkarray[i].x, atkarray[i].y, 1) / 10000
			end
		end
		for i = 1, num - 1 do
			for j = i + 1, num do
				if atkarray[i].p < atkarray[j].p then
					atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
				elseif atkarray[i].p == atkarray[j].p and math.random(2) > 1 then
					atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
				end
			end
		end

		local select = 1

		War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
		War_MovePerson(atkarray[select].x, atkarray[select].y)
		War_Fight_Sub(WAR.CurID, kfid, atkarray[select].ax, atkarray[select].ay)
		--阿凡提攻击完躲开
		if pid == 606 then
			WAR.Person[WAR.CurID]["移动步数"] = 10
			War_AutoEscape()
			War_RestMenu()
		end
	else
		--葵花尊者，打不到人会瞬移
		if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and pid == 27 and kuihuameiying() then
			AIThink(kfid)
		else
			--打不到人，考虑吃药
			local jl, nx, ny = War_realjl()
			AutoMove()
			--默认为休息
			local what_to_do = 0
			local can_eat_drug = 0
			--[[非我方，会考虑吃药
			if WAR.Person[WAR.CurID]["我方"] == false then
				can_eat_drug = 1
			--如果是我方，只有在队且允许才会吃药
			else
				if inteam(pid) and JY.Person[pid]["是否吃药"] == 1 then
					can_eat_drug = 1
				end
			end]]
			--左右第二下，不能吃药
			if WAR.ZYHB == 2 then
				can_eat_drug = 0
			end
			--1:吃体力药 2：吃血 3：医疗 4：吃内力 5：吃解毒
			if can_eat_drug == 1 then
				local r = -1
				--体力低于10，吃体力药
				if JY.Person[pid]["体力"] < 10 then
					r = War_ThinkDrug(4)
					if r >= 0 then
						what_to_do = 1
					end
				end
				local rate = -1
				if JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 5 then
					rate = 90
				elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 4 then
					rate = 70
				elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 3 then
					rate = 50
				elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 2 then
					rate = 25
				end
				--内伤也增加吃血药几率
				if JY.Person[pid]["受伤程度"] > 50 then
					rate = rate + 50
				end
				if Rnd(100) < rate then
					r = War_ThinkDrug(2)
					if r >= 0 then				--如果有药吃药
						what_to_do = 2
					else
						r = War_ThinkDoctor()		--如果没有药，考虑医疗
						if r >= 0 then
							what_to_do = 3
						end
					end
				end
				--考虑内力
				rate = -1
				if JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 6 then
					rate = 100
				elseif JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 5 then
					rate = 75
				elseif JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 4 then
					rate = 50
				end
				if Rnd(100) < rate then
					r = War_ThinkDrug(3)
					if r >= 0 then
						what_to_do = 4
					end
				end
				rate = -1
				if CC.PersonAttribMax["中毒程度"] * 3 / 4 < JY.Person[pid]["中毒程度"] then
					rate = 60
				else
					if CC.PersonAttribMax["中毒程度"] / 2 < JY.Person[pid]["中毒程度"] then
						rate = 30
					end
				end
				--半血以下，才吃解毒药
				if JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 2 and Rnd(100) < rate then
					r = War_ThinkDrug(6)
					if r >= 0 then
						what_to_do = 5
					end
				end
			end
			--吃药flag 2：生命 3：内力 4：体力 6：解毒
			if what_to_do == 0 then
				War_RestMenu()
			elseif what_to_do == 1 then
				War_AutoEatDrug(4)
			elseif what_to_do == 2 then
				War_AutoEatDrug(2)
			elseif what_to_do == 3 then
				War_AutoDoctor()
			elseif what_to_do == 4 then
				War_AutoEatDrug(3)
			elseif what_to_do == 5 then
				War_AutoEatDrug(6)
			end
		end
	end
end

function AutoMove()
	local x, y = nil, nil
	local minDest = math.huge
	local enemyid = War_AutoSelectEnemy()   --选择最近敌人

	War_CalMoveStep(WAR.CurID,100,0);   --计算移动步数 假设最大100步

	for i=0,CC.WarWidth-1 do
		for j=0,CC.WarHeight-1 do
			local dest=GetWarMap(i,j,3);
			if dest <128 then
				local dx=math.abs(i-WAR.Person[enemyid]["坐标X"])
				local dy=math.abs(j-WAR.Person[enemyid]["坐标Y"])
				if minDest>(dx+dy) then        --此时x,y是距离敌人的最短路径，虽然可能被围住
					minDest=dx+dy;
					x=i;
					y=j;
				elseif minDest==(dx+dy) then
					if Rnd(2)==0 then
						x=i;
						y=j;
					end
				end
			end
		end
	end

	if minDest < math.huge then   --有路可走
	    while true do    --从目的位置反着找到可以移动的位置，作为移动的次序
			local i=GetWarMap(x,y,3);
			if i<=WAR.Person[WAR.CurID]["移动步数"] then
				break;
			end

			if GetWarMap(x-1,y,3)==i-1 then
				x=x-1;
			elseif GetWarMap(x+1,y,3)==i-1 then
				x=x+1;
			elseif GetWarMap(x,y-1,3)==i-1 then
				y=y-1;
			elseif GetWarMap(x,y+1,3)==i-1 then
				y=y+1;
			end
	    end
		War_MovePerson(x,y);    --移动到相应的位置
	end
end

function GetMovePoint(x, y, flag)
	local point = 0
	local wofang = WAR.Person[WAR.CurID]["我方"]
	local movearray = MY_CalMoveStep(x, y, 16, 1)
	for i = 1, 16 do
		local step_num = movearray[i].num
		if step_num ~= nil then
			if step_num == 0 then
				break;
			end
			for j = 1, step_num do
				local xx = movearray[i].x[j]
				local yy = movearray[i].y[j]
				local v = GetWarMap(xx, yy, 2)
				if v ~= -1 then
					if v == WAR.CurID then
						break;
					else
						if WAR.Person[v]["我方"] == wofang then
							point = point + i * 2 - 26
						elseif WAR.Person[v]["我方"] ~= wofang then
							if flag ~= nil then
								point = point + i - 17
							else
								point = point + 26 - i
							end
						end
					end
				end
			end
		end
	end
	return point
end

function MY_CalMoveStep(x, y, stepmax, flag)
	CleanWarMap(3, 255)
	local steparray = {}
	for i = 0, stepmax do
		steparray[i] = {}
		steparray[i].bushu = {}
		steparray[i].x = {}
		steparray[i].y = {}
	end
	SetWarMap(x, y, 3, 0)
	steparray[0].num = 1
	steparray[0].bushu[1] = stepmax
	steparray[0].x[1] = x
	steparray[0].y[1] = y
	War_FindNextStep(steparray, 0, flag)
	return steparray
end

function GetAtkNum(x, y, warid, kungfuid)
	local pid = WAR.Person[warid]["人物编号"]
	local targets = GetValidTargets(warid, kungfuid)
  	local enemys = GetNonEmptyTargets(warid, targets, x, y)
	if enemys == nil then
		return 0, 0, 0
	end
	local target = {}
	target.x = 0
	target.y = 0
	target.p = 0
	target.id = 9999
	for i = 1, #enemys do
		local mid = GetWarMap(enemys[i].x + x, enemys[i].y + y, 2)
		local eid = WAR.Person[mid]["人物编号"]
		local dmg = War_PredictDamage(pid, eid, kungfuid)
		local ehp = JY.Person[eid]["生命"]
		local rate = dmg * 1000 / ehp
		if rate > target.p then
			target.x = enemys[i].x + x
			target.y = enemys[i].y + y
			target.p = rate
			target.id = mid
		end
	end
	--奇门遁甲
	if GetWarMap(x, y, 6) == 3 then
		target.p = target.p * 1.1
	elseif GetWarMap(x, y, 6) == 2 then
		target.p = target.p * 1.01
	end

	if target.p > 0 and kungfuid == 27 then
		if War_Direct(x, y, target.x, target.y) == WAR.Person[target.id]["人方向"] then
			target.p = target.p * 1.3
		end
	end

 	return target.p, target.x, target.y
end

function War_FindNextStep1(steparray,step,id,idb)      --设置下一步可移动的坐标
	--被上面的函数调用   
	local num=0;
	local step1=step+1;

	steparray[step1]={};
	steparray[step1].bushu={};
	steparray[step1].x={};
	steparray[step1].y={};

	local function fujinnum(tx,ty)
		local tnum=0
		local wofang=WAR.Person[id]["我方"]
		local tv;
		tv=GetWarMap(tx+1,ty,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["我方"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["我方"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx-1,ty,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["我方"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["我方"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx,ty+1,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["我方"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["我方"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx,ty-1,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["我方"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["我方"]~=wofang then
				tnum=tnum+1
			end
		end
		return tnum
	end

	for i=1,steparray[step].num do
		--if steparray[step].bushu[i]<128 then
		steparray[step].bushu[i]=steparray[step].bushu[i]+1;
	    local x=steparray[step].x[i];
	    local y=steparray[step].y[i];
	    if x+1<CC.WarWidth-1 then                        --当前步数的相邻格
		    local v=GetWarMap(x+1,y,3);
			if v ==255 and War_CanMoveXY(x+1,y,0)==true then
                num= num+1;
                steparray[step1].x[num]=x+1;
                steparray[step1].y[num]=y;
				SetWarMap(x+1,y,3,step1);
				local mnum=fujinnum(x+1,y);
				if mnum==-1 then
					return steparray[step].bushu[i],x+1,y
				else
					steparray[step1].bushu[num]=steparray[step].bushu[i]+mnum;
				end
			end
		end

	    if x-1>0 then                        --当前步数的相邻格
		    local v=GetWarMap(x-1,y,3);
			if v ==255 and War_CanMoveXY(x-1,y,0)==true then
                 num=num+1;
                steparray[step1].x[num]=x-1;
                steparray[step1].y[num]=y;
				SetWarMap(x-1,y,3,step1);
				local mnum=fujinnum(x-1,y);
				if mnum==-1 then
					return steparray[step].bushu[i],x-1,y
				else
					steparray[step1].bushu[num]=steparray[step].bushu[i]+mnum;
				end
			end
		end

	    if y+1<CC.WarHeight-1 then                        --当前步数的相邻格
		    local v=GetWarMap(x,y+1,3);
			if v ==255 and War_CanMoveXY(x,y+1,0)==true then
                 num= num+1;
                steparray[step1].x[num]=x;
                steparray[step1].y[num]=y+1;
				SetWarMap(x,y+1,3,step1);
				local mnum=fujinnum(x,y+1);
				if mnum==-1 then
					return steparray[step].bushu[i],x,y+1
				else
					steparray[step1].bushu[num]=steparray[step].bushu[i]+mnum;
				end
			end
		end

	    if y-1>0 then                        --当前步数的相邻格
		    local v=GetWarMap(x ,y-1,3);
			if v ==255 and War_CanMoveXY(x,y-1,0)==true then
                num= num+1;
                steparray[step1].x[num]=x ;
                steparray[step1].y[num]=y-1;
				SetWarMap(x ,y-1,3,step1);
				local mnum=fujinnum(x,y-1);
				if mnum==-1 then
					return steparray[step].bushu[i],x,y-1
				else
					steparray[step1].bushu[num]=steparray[step].bushu[i]+mnum;
				end
			end
		end
		--end
	end
	if num==0 then return -1 end;
    steparray[step1].num=num;
	for i=1,num-1 do
		for j=i+1,num do
			if steparray[step1].bushu[i]>steparray[step1].bushu[j] then
				steparray[step1].bushu[i],steparray[step1].bushu[j]=steparray[step1].bushu[j],steparray[step1].bushu[i]
				steparray[step1].x[i],steparray[step1].x[j]=steparray[step1].x[j],steparray[step1].x[i]
				steparray[step1].y[i],steparray[step1].y[j]=steparray[step1].y[j],steparray[step1].y[i]
			end
		end
	end

	return War_FindNextStep1(steparray,step1,id,idb)
end
--修炼物品
function War_PersonTrainDrug(pid)
	local p = JY.Person[pid]
	local thingid = p["修炼物品"]
	if thingid < 0 then
		return
	end
	if JY.Thing[thingid]["练出物品需经验"] <= 0 then
		return
	end
	local needpoint = (7 - math.modf(p["资质"] / 15)) * JY.Thing[thingid]["练出物品需经验"]
	if p["物品修炼点数"] < needpoint then
		return
	end

	local haveMaterial = 0
	local MaterialNum = -1
	for i = 1, CC.MyThingNum do
		if JY.Base["物品" .. i] == JY.Thing[thingid]["需材料"] then
			haveMaterial = 1
			MaterialNum = JY.Base["物品数量" .. i]
		end
	end

	--材料足够
	if haveMaterial == 1 then
		local enough = {}
		local canMake = 0
		for i = 1, 5 do
			if JY.Thing[thingid]["练出物品" .. i] >= 0 and JY.Thing[thingid]["需要物品数量" .. i] <= MaterialNum then
				canMake = 1
				enough[i] = 1
			else
				enough[i] = 0
			end
		end
		--可以练出
		if canMake == 1 then
			local makeID = nil
			while true do
				makeID = Rnd(5) + 1
				if thingid == 221 and pid == 88 and enough[4] == 1 then
					makeID = 4
				end
				if thingid == 220 and pid == 89 and enough[4] == 1 then
					makeID = 4
				end
				if enough[makeID] == 1 then
					break;
				end
			end

			local newThingID = JY.Thing[thingid]["练出物品" .. makeID]
			DrawStrBoxWaitKey(string.format("%s 制造出 %s", p["姓名"], JY.Thing[newThingID]["名称"]), C_WHITE, CC.DefaultFont)
			if instruct_18(newThingID) == true then
				instruct_32(newThingID, 1)
			else
				instruct_32(newThingID, 1)
			end
			instruct_32(JY.Thing[thingid]["需材料"], -JY.Thing[thingid]["需要物品数量" .. makeID])
			p["物品修炼点数"] = 0
		end
	end
end
--计算敌人中毒点数
--pid 使毒人，
--enemyid  中毒人
function War_PoisonHurt(pid, enemyid)
	local vv = math.modf((JY.Person[pid]["用毒能力"] - JY.Person[enemyid]["抗毒能力"]) / 4)
	--胡青牛在场王难姑用毒+50
	if JY.Status == GAME_WMAP then
		for i,v in pairs(CC.AddPoi) do
			if match_ID(pid, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["人物编号"], v[2]) and WAR.Person[wid]["死亡"] == false then
						vv = vv + v[3] / 4
					end
				end
			end
		end
	end
	vv = vv - JY.Person[enemyid]["内力"] / 200
	for i = 1, 10 do
		if JY.Person[enemyid]["武功" .. i] == 108 then
			vv = 0
		end
	end
	vv = math.modf(vv)
	if vv < 0 then
		vv = 0
	end
	return AddPersonAttrib(enemyid, "中毒程度", vv)
end

--人物按轻功进行排序
function WarPersonSort(flag)
	for i = 0, WAR.PersonNum - 1 do
		local id = WAR.Person[i]["人物编号"]
		local p = JY.Person[id]
		WAR.Person[i]["轻功"] = JY.Person[id]["轻功"]
		--敌方的战场轻功会根据内力和等级加成
		--[[情侣加成
		for ii,v in pairs(CC.AddSpd) do
			if match_ID(id, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["人物编号"], v[2]) and WAR.Person[wid]["死亡"] == false then
						WAR.Person[i]["轻功"] = WAR.Person[i]["轻功"] + v[3]
					end
				end
			end
		end]]
	end
	if flag ~= nil then
		return
	end
	for i = 0, WAR.PersonNum - 2 do
		local maxid = i
		for j = i, WAR.PersonNum - 1 do
			if WAR.Person[maxid]["轻功"] < WAR.Person[j]["轻功"] then
				maxid = j;
			end
		end
		WAR.Person[maxid], WAR.Person[i] = WAR.Person[i], WAR.Person[maxid]
	end
end

--显示非攻击时的点数
function War_Show_Count(id, str)
	if JY.Restart == 1 then
		return
	end

	local pid = WAR.Person[id]["人物编号"];
	local x = WAR.Person[id]["坐标X"];
	local y = WAR.Person[id]["坐标Y"];

	local hp = WAR.Person[id]["生命点数"];
	local mp = WAR.Person[id]["内力点数"];
	local tl = WAR.Person[id]["体力点数"];
	local ed = WAR.Person[id]["中毒点数"];
	local dd = WAR.Person[id]["解毒点数"];
	local ns = WAR.Person[id]["内伤点数"];

	local show = {x, y, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};		--x, y, 生命, 内力, 体力, 封穴, 流血, 中毒, 解毒, 内伤，冰封，灼烧

	if hp ~= nil and hp ~= 0 then		--显示生命
		if hp > 0 then
			show[3] = "生命+"..hp;
		else
			show[3] = "生命"..hp;
		end
	end

	if mp ~= nil and mp ~= 0 then		--显示内力
		if mp > 0 then
			show[5] = "内力+"..mp;
		else
			show[5] = "内力"..mp;
		end
	end

	if tl ~= nil and tl ~= 0 then		--显示体力
		if tl > 0 then
			show[6] = "体力+"..tl;
		else
			show[6] = "体力"..tl;
		end
	end

    if WAR.FXXS[WAR.Person[id]["人物编号"]] ~= nil and WAR.FXXS[WAR.Person[id]["人物编号"]] == 1 then			--显示是否封穴
       	show[7] = "封穴 "..WAR.FXDS[WAR.Person[id]["人物编号"]];
       	WAR.FXXS[WAR.Person[id]["人物编号"]] = 0
    end

    if WAR.LXXS[WAR.Person[id]["人物编号"]] ~=nil and WAR.LXXS[WAR.Person[id]["人物编号"]] == 1 then		--显示是否被流血
      	show[8] = "流血 "..WAR.LXZT[WAR.Person[id]["人物编号"]];
        WAR.LXXS[WAR.Person[id]["人物编号"]] = 0
    end

	if ed ~= nil and ed ~= 0 then		--显示中毒
		show[9] = "中毒+"..ed;
	end

	if dd ~= nil and dd ~= 0 then		--显示解毒
		show[4] = "中毒-"..dd;
	end

	if ns ~= nil and ns ~= 0 then		--显示内伤
		if ns > 0 then
			show[10] = "内伤↑"..ns;
		else
			show[10] = "内伤↓"..-ns;
		end
	end

	if WAR.BFXS[WAR.Person[id]["人物编号"]] == 1 then		--显示是否被冰封
		show[11] = "冰封 "..JY.Person[WAR.Person[id]["人物编号"]]["冰封程度"];
		WAR.BFXS[WAR.Person[id]["人物编号"]] = 0
	end

	if WAR.ZSXS[WAR.Person[id]["人物编号"]] == 1 then		--显示是否被灼烧
		show[12] = "灼烧 "..JY.Person[WAR.Person[id]["人物编号"]]["灼烧程度"];
		WAR.ZSXS[WAR.Person[id]["人物编号"]] = 0
	end

	--记录哪个位置上有点数
	local showValue = {};
	local showNum = 0;
	for i=3, 12 do
		if show[i] ~= nil then
			showNum = showNum + 1;
			showValue[showNum] = i;
		end
	end

	if showNum == 0 then
		return;
	end

	local hb = GetS(JY.SubScene, x, y, 4);

	local ll = string.len(show[showValue[1]]);	--长度

	local w = ll * CC.DefaultFont / 2 + 1
	local clip = {x1 = CC.ScreenW / 2 - w/2 - CC.XScale/2, y1 = CC.YScale + CC.ScreenH / 2 - hb, x2 = CC.XScale + CC.ScreenW / 2 + w, y2 = CC.YScale + CC.ScreenH / 2 + CC.DefaultFont + 1}
	local area = (clip.x2 - clip.x1) * (clip.y2 - clip.y1) + CC.DefaultFont*4		--绘画的范围
	local surid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)		--绘画句柄

	for i = 5, 18 do
		if JY.Restart == 1 then
			break
		end
		local tstart = lib.GetTime()
		local y_off = i * 2

		lib.SetClip(0, 0, CC.ScreenW, CC.ScreenH)
		lib.LoadSur(surid, 0, 0)
		--显示文字
		if str ~= nil then
			DrawString(clip.x1 - #str*CC.Fontsmall/5 + 30, clip.y1 - y_off - CC.DefaultFont*4, str, C_WHITE, CC.Fontsmall);
		end
		for j=1, showNum do
			local c = showValue[j] - 1;
			if showValue[j] == 3 and (string.sub(show[3],1,1) == "-" or string.sub(show[3],2,2) == "-") then		--减少生命，显示为红色
				c = 1;
			end
			DrawString(clip.x1, clip.y1 - y_off - (showNum-j+1)*CC.DefaultFont, show[showValue[j]], WAR.L_EffectColor[c], CC.DefaultFont);
		end

		ShowScreen(1)
		lib.SetClip(0, 0, 0, 0)		--清除
		local tend = lib.GetTime()
		if tend - tstart < CC.BattleDelay then
			lib.Delay(CC.BattleDelay - (tend - tstart))
		end
	end

	lib.SetClip(0, 0, 0, 0)		--清除
	WAR.Person[id]["生命点数"] = nil;
	WAR.Person[id]["内力点数"] = nil;
	WAR.Person[id]["体力点数"] = nil;
	WAR.Person[id]["中毒点数"] = nil;
	WAR.Person[id]["解毒点数"] = nil;
	WAR.Person[id]["内伤点数"] = nil;

	lib.FreeSur(surid)
end

--计算医疗量
--id1 医疗id2, 返回id2生命增加点数
function ExecDoctor(id1, id2)
	if JY.Person[id1]["体力"] < 50 then
		return 0
	end
	local add = JY.Person[id1]["医疗能力"]
	local value = JY.Person[id2]["受伤程度"]
	if add + 20 < value then
		return 0
	end

	-- 平一指，医疗量和杀人数有关
	if match_ID(id1, 28) and JY.Status == GAME_WMAP then
		add = math.modf(JY.Person[id1]["医疗能力"] * (1 + WAR.PYZ / 10))
	end

	--战斗状态的医疗
	--胡斐在场程灵素医疗+120
	--王难姑在场胡青牛医疗+50
	if JY.Status == GAME_WMAP then
		for i,v in pairs(CC.AddDoc) do
			if match_ID(id1, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["人物编号"], v[2]) and WAR.Person[wid]["死亡"] == false then
						add = add + v[3]
					end
				end
			end
		end
	end

	add = add - (add) * value / 200
	add = math.modf(add) + Rnd(5)

	local n = AddPersonAttrib(id2, "受伤程度", -math.modf((add) / 10))
	--蓝烟清：医疗时显示内伤减少
	if JY.Status == GAME_WMAP then
		local p = -1;
		for wid = 0, WAR.PersonNum - 1 do
			if WAR.Person[wid]["人物编号"] == id2 and WAR.Person[wid]["死亡"] == false then
				p = wid;
				break;
			end
		end
		WAR.Person[p]["内伤点数"] = n;
	end
	return AddPersonAttrib(id2, "生命", add)
end

--无酒不欢：计算武功伤害，WAR.CurID为攻击方
function War_WugongHurtLife(enemyid, wugong, level, ang, x, y)

	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local eid = WAR.Person[enemyid]["人物编号"]
	--气防
	local dng = 0
	local WGLX = JY.Wugong[wugong]["武功类型"]

	--无酒不欢：记录人物血量
	WAR.Person[enemyid]["Life_Before_Hit"] = JY.Person[eid]["生命"]

	--松风剑法背刺效果
    if wugong == 27 and IsBackstab(WAR.CurID, enemyid) then
		JY.Person[eid]["受伤程度"] = JY.Person[eid]["受伤程度"] + 10
		WAR.Person[enemyid]["特效动画"] = 93
		Set_Eff_Text(enemyid, "特效文字2", "青城摧心掌")
    end

	local hurt = War_CalculateDamage(pid, eid, wugong)
	JY.Person[pid]["主运内功"] = wugong
	if WAR.DZXY ~= 1 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[enemyid]["我方"] and JY.Person[eid]["主运内功"] > 0 then
		WAR.Person[enemyid]["反击武功"] = JY.Person[eid]["主运内功"]
	end
	--误伤打到自己人
	--[[if WAR.Person[WAR.CurID]["我方"] == WAR.Person[enemyid]["我方"] then
		--我方
		if WAR.Person[WAR.CurID]["我方"] then
			--水笙误伤加血
			if match_ID(pid, 589) then
				hurt = -(math.modf(hurt) + Rnd(3))
			--其他人误伤30%
			else
				hurt = math.modf(hurt * 0.3) + Rnd(3)
			end
		--NPC，误伤=20%
		else
			--倾国反弹100%
			if WAR.NZQK == 3 then
			
			--触发逆转乾坤，NPC误伤提高至50%
			elseif WAR.NZQK == 0 then
				hurt = math.modf(hurt * 0.2) + Rnd(3)
			else
				hurt = math.modf(hurt * 0.5) + Rnd(3)
			end
		end
	end]]

	--无酒不欢：伤害的结算到此为止，扣除被攻击方血量
	JY.Person[eid]["生命"] = JY.Person[eid]["生命"] - hurt
	--人物死亡
	if JY.Person[eid]["生命"] < 0 then
		JY.Person[eid]["生命"] = 0
		WAR.Person[WAR.CurID]["经验"] = WAR.Person[WAR.CurID]["经验"] + JY.Person[eid]["等级"] * 5
		WAR.Person[enemyid]["反击武功"] = -1		--如果被打死则不会触发反击
		if WAR.SZSD == eid then						--取消死战标记
			WAR.SZSD = -1
		end
	end
	--[[误伤不显示动画
	if DWPD() == false then
		WAR.Person[enemyid]["特效动画"] = -1
		WAR.Person[enemyid]["特效文字0"] = nil
		WAR.Person[enemyid]["特效文字1"] = nil
		WAR.Person[enemyid]["特效文字2"] = nil
		WAR.Person[enemyid]["特效文字3"] = nil
		WAR.Person[enemyid]["特效文字4"] = nil
	end]]

	return limitX(hurt, 0, hurt);
end

-- 绘制战斗地图
-- flag=0  绘制基本战斗地图
--     =1  显示可移动的路径，(v1,v2)当前移动坐标，白色背景(雪地战斗)
--     =2  显示可移动的路径，(v1,v2)当前移动坐标，黑色背景
--     =3  命中的人物用白色轮廓显示
--     =4  战斗动作动画  v1 战斗人物pic, v2贴图所属的加载文件id
--                       v3 武功效果pic  -1表示没有武功效果
function WarDrawMap(flag, v1, v2, v3, v4, v5, ex, ey)
	local x = WAR.Person[WAR.CurID]["坐标X"]
	local y = WAR.Person[WAR.CurID]["坐标Y"]
	if not v4 then
		v4 = JY.SubScene
	end
	if not v5 then
		v5 = -1;
	end

	if flag == 0 then
		lib.DrawWarMap(0, x, y, 0, 0, -1, v4)
	elseif flag == 1 then
		--胡斐居，雪山，有间客栈，凌霄城，北京城，华山绝顶
		if v4 == 0 or v4 == 2 or v4 == 3 or v4 == 39 or v4 == 107 or v4 == 111 then
			lib.DrawWarMap(1, x, y, v1, v2, -1, v4)
		else
			lib.DrawWarMap(2, x, y, v1, v2, -1, v4)
		end
	elseif flag == 2 then
			lib.DrawWarMap(3, x, y, 0, 0, -1, v4)
	elseif flag == 4 then
		lib.DrawWarMap(4, x, y, v1, v2, v3, v4,v5, ex, ey)
	end

	if WAR.ShowHead == 1 then
		WarShowHead()
	end

	if CONFIG.HPDisplay == 1 then
		if WAR.ShowHP == 1 then
			HP_Display_When_Idle()	--常态显血
		end
	end
end

--敌方战斗数据
function WarSelectEnemy()
	--敌方数据特别调整
	if PNLBD[WAR.ZDDH] ~= nil then
		PNLBD[WAR.ZDDH]()
	end

	for i = 1, 20 do
		if WAR.Data["敌人" .. i] > 0 then
			--冰糖恋：单挑陈达海
			if WAR.ZDDH == 92 and GetS(87,31,33,5) == 1 then
				for i=2,5 do
					WAR.Data["敌人" .. i] = -1;
				end
			end

			--无酒不欢：新论剑敌人
			if WAR.ZDDH == 266 then
				WAR.Data["敌人1"] = GetS(85, 40, 38, 4)
			end

			WAR.Person[WAR.PersonNum]["人物编号"] = WAR.Data["敌人" .. i]
			WAR.Person[WAR.PersonNum]["我方"] = false
			WAR.Person[WAR.PersonNum]["坐标X"] = WAR.Data["敌方X" .. i]
			WAR.Person[WAR.PersonNum]["坐标Y"] = WAR.Data["敌方Y" .. i]
			WAR.Person[WAR.PersonNum]["死亡"] = false
			WAR.Person[WAR.PersonNum]["人方向"] = 1
			--无酒不欢：调整战斗初始面向
			--战海大富
			if WAR.ZDDH == 259 then
				WAR.Person[WAR.PersonNum]["人方向"] = 2
			end
			--双挑公孙止
			if WAR.ZDDH == 273 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--杨过单金轮
			if WAR.ZDDH == 275 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--战杨龙
			if WAR.ZDDH == 75 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--蒙哥
			if WAR.ZDDH == 278 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--芷若夺掌门
			if WAR.ZDDH == 279 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--单挑赵敏
			if WAR.ZDDH == 293 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--玄冥二老
			if WAR.ZDDH == 295 then
				WAR.Person[WAR.PersonNum]["人方向"] = 3
			end
			--三挑岳不群
			if WAR.ZDDH == 298 then
				WAR.Person[WAR.PersonNum]["人方向"] = 2
			end
			WAR.PersonNum = WAR.PersonNum + 1
		end
	end
end

--计算战斗人物贴图
function WarCalPersonPic(id)
	local n = 5106
	n = n + JY.Person[WAR.Person[id]["人物编号"]]["头像代号"] * 8 + WAR.Person[id]["人方向"] * 2
	return n
end

--计算标准主角特殊行走贴图
function WarCalPersonPic2(id, gender)
	local n = 5058
	if gender == 1 then
		n = 5010
	end
	n = n + WAR.Person[id]["人方向"] * 12
	return n
end

--战斗是否结束
function War_isEnd()
	for i = 0, WAR.PersonNum - 1 do
		if JY.Person[WAR.Person[i]["人物编号"]]["生命"] <= 0 then
			WAR.Person[i]["死亡"] = true
		end
	end
	WarSetPerson()
	Cls()
	ShowScreen()
	local myNum = 0
	local EmenyNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			if WAR.Person[i]["我方"] == true then
				myNum = 1
			else
				EmenyNum = 1
			end
		end
	end

	if EmenyNum == 0 then
		return 1;
	end
	if myNum == 0 then
		return 2;
	end
	return 0
end

--无酒不欢：战斗是否结束2
function War_isEnd2()
	local myNum = 0
	local EmenyNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			if WAR.Person[i]["我方"] == true then
				myNum = 1
			else
				EmenyNum = 1
			end
		end
	end

	if EmenyNum == 0 then
		return 1;
	end
	if myNum == 0 then
		return 2;
	end
	return 0
end

--设置战斗全局变量
function WarSetGlobal()
	WAR = {}
	WAR.Data = {}
	WAR.Person = {}
	WAR.MCRS = 0 --无酒不欢：每场战斗选的人数
	for i = 0, 30 do
		WAR.Person[i] = {}
		WAR.Person[i]["人物编号"] = -1
		WAR.Person[i]["我方"] = true
		WAR.Person[i]["坐标X"] = -1
		WAR.Person[i]["坐标Y"] = -1
		WAR.Person[i]["死亡"] = true
		WAR.Person[i]["人方向"] = -1
		WAR.Person[i]["贴图"] = -1
		WAR.Person[i]["贴图类型"] = 0
		WAR.Person[i]["轻功"] = 0
		WAR.Person[i]["移动步数"] = 0
		WAR.Person[i]["经验"] = 0
		WAR.Person[i]["自动选择对手"] = -1
		WAR.Person[i].Move = {}
		WAR.Person[i].Action = {}
		WAR.Person[i].Time = 0
		WAR.Person[i].TimeAdd = 0
		WAR.Person[i].SpdAdd = 0
		WAR.Person[i].Point = 0
		WAR.Person[i]["特效动画"] = -1
		WAR.Person[i]["反击武功"] = -1
		WAR.Person[i]["特效文字0"] = nil
		WAR.Person[i]["特效文字1"] = nil
		WAR.Person[i]["特效文字2"] = nil
		WAR.Person[i]["特效文字3"] = nil
		WAR.Person[i]["特效文字4"] = nil	--无酒不欢：加到这里 8-11
	end
	WAR.PersonNum = 0
	WAR.AutoFight = 0
	WAR.CurID = -1
	WAR.SXTJ = 0		--时序
	WAR.SSX_Counter = 0	--三时序计数器
	WAR.WSX_Counter = 0	--五时序计数器
	WAR.LSX_Counter = 0	--六时序计数器
	WAR.JSX_Counter = 0	--九时序计数器
	WAR.ZSHY = {}		--转瞬红颜计数器
	WAR.WGWL = 0		--记录武功10级的攻击力
	WAR.ZYHB = 0		--左右互搏，1：发动左右的回合，2：左右的额外回合
	WAR.ZYHBP = -1		--记录发动左右的人的编号
	WAR.PREVIEW = -1	--记录发动预览的人的编号
	WAR.ZHB = 0			--周伯通的追加左右判定
	WAR.AQBS = 0		--暗器倍数
	WAR.BJ = 0			--暴击
	WAR.XK = 0			--西狂之怒啸
	WAR.XK2 = nil
	WAR.TD = -1			--偷盗
	WAR.TDnum = 0		--偷盗数量
	WAR.HTSS = 0		--医生大招
	WAR.ZSF = 0			--张三丰万法自然
	WAR.XZZ = 0			--虚竹福泽加护
	WAR.KFKJ = 0		--封不平狂风快剑
	WAR.WCY = {}		--一灯复活
	WAR.CYZX = {} 		--王重阳复活
	WAR.BDQS = 0		--王重阳北斗真打状态层数
	WAR.QCF = 0			--戚长发复活
	WAR.HTS = 0			--何铁手五毒随机2-5倍威力
	WAR.FS = 0			--四帮主之战，乔峰用铁掌
	WAR.ZBT = 1			--周伯通，每行动一次，攻击时伤害一+10%
	WAR.HQT = 0			--霍青桐 杀体力
	WAR.CY = 0			--程英 杀内力
	WAR.HDWZ = 0		--霍都随机上毒
	WAR.ZJZ = 0			--朱九真，随机得到食材
	WAR.YJ = 0			--阎基偷钱
	WAR.XMH = 0			--薛慕华 复活一个人
	WAR.PYZ = 0			--平一指杀人
	WAR.DJGZ = 0		--刀剑归真
	WAR.WS = 0			--误伤
	WAR.ACT = 1			--连击回数
	WAR.ZDDH = -1		--战斗代号
	WAR.NO1 = -1		--旧版论剑第一名
	WAR.TJAY = 0		--太极奥义
	WAR.LYSH = 0 		--两仪守护
	WAR.TKXJ = 0		--太空卸劲
	WAR.DZXY = 0		--斗转星移
	WAR.fthurt = 0		--乾坤反弹的伤害
	WAR.LXZQ = 0		--拳主大招
	WAR.LXYZ = 0		--指主大招
	WAR.JSYX = 0		--剑神大招
	WAR.ASKD = 0		--刀主大招
	WAR.YZHYZ = 0		--刀主大招增加怒气计数
	WAR.GCTJ = 0		--奇门大招
	WAR.JSTG = 0		--天罡大招
	WAR.YTML = 0 		--毒王大招
	WAR.NGXS = 0		--内功攻击的系数
	WAR.TXZZ = 0		--太玄之重
	WAR.MMGJ = 0		--盲目攻击
	WAR.TFBW = 0		--听风辨位的文字记录
	WAR.TLDWX = 0		--天罗地网的文字记录
	WAR.JSAY = 0		--金蛇奥义
	WAR.TLDW = {}		--天罗地网
	WAR.OYFXL = 0 		--欧阳锋根据蛤蟆蓄力增加伤害
	WAR.XDLeech = 0		--血刀吸血量
	WAR.WYXLeech = 0	--韦一笑吸血量
	WAR.TMGLeech = 0	--天魔功吸血量
	WAR.XHSJ = 0		--血河神鉴吸血量
	WAR.WDRX = 0		--宋远桥使用太极拳或太极剑攻击后自动进入防御状态
	WAR.KMZWD = 0 		--周伯通空明之武道
	WAR.ARJY = 0		--黯然极意
	WAR.LFHX = 0 		--林朝英流风回雪
	WAR.YYBJ = 0 		--郭靖：有余不尽
	WAR.YNXJ = 0		--玉女心经：夭矫空碧
	WAR.HXZYJ = 0		--会心之一击
	WAR.QQSH1 = 0		--琴棋书画之持瑶琴
	WAR.QQSH2 = 0		--琴棋书画之妙笔丹青
	WAR.QQSH3 = 0		--琴棋书画之倚天屠龙功
	WAR.YZQS = 0		--一震七伤
	WAR.TYJQ = 0		--阿青天元剑气
	WAR.OYK = 0 		--欧阳克灵蛇拳
	WAR.JQBYH = 0		--六脉：剑气碧烟横
	WAR.CMDF = 0		--沧溟刀法
	WAR.NZQK = 0		--逆转乾坤
	WAR.TXXS = {} 		--特效点数显示
	WAR.BXCF = 0 		--袁承志碧血长风
	WAR.FLHS1 = 0		--其疾如风
	WAR.FLHS2 = 0		--其徐如林
	WAR.FLHS4 = 0		--不动如山
	WAR.FLHS5 = 0		--难知如阴
	WAR.FLHS6 = 0		--动如雷震
	WAR.NGJL = 0		--当前加力内功编号
	WAR.NGHT = 0		--当前护体内功编号
	WAR.CQSX = 0		--除却四相
	WAR.BMXH = 0		--三大吸功
	WAR.ZYYD = 0		--记录左右的圣火移动步数
	WAR.LMSJwav = 0		--六脉神剑的音效
	WAR.JGZ_DMZ = 0		--达摩掌
	WAR.LHQ_BNZ = 0		--般若掌
	WAR.WD_CLSZ = 0		--赤练神掌
	WAR.ShowHead = 0	--显示右下角头像信息
	WAR.Effect = 0		--本次攻击的效果，2：伤害，3：杀内，4：医疗，5：上毒，6：解毒
	WAR.Delay = 0
	WAR.LifeNum = 0
	WAR.EffectXY = nil
	WAR.EffectXYNum = 0
	WAR.tmp = {}		--200：蛤蟆功蓄力，1000：欧阳锋逆运走火，2000：太极拳蓄力，3000：神照复活，5000：头像编号
	WAR.Actup = {}		--蓄力记录
	WAR.Defup = {}		--防御记录
	WAR.Wait = {}		--等待记录
	WAR.HMGXL = {}		--蛤蟆蓄力增加300集气
	WAR.Weakspot = {}	--破绽计数
	WAR.KHBX = 0		--葵花刺目
	WAR.KHCM = {}		--被刺目的人记录
	WAR.LQZ = {}		--怒气值
	WAR.FXDS = {}		--封穴点数
	WAR.FXXS = {}		--封穴显示
	WAR.LXZT = {}		--流血点数
	WAR.LXXS = {}		--流血显示
	WAR.BFXS = {}		--冰封显示
	WAR.ZSXS = {}		--灼烧显示
	WAR.SZJPYX = {}		--已经提供过实战的人记录（被打死的）
	WAR.TZ_MRF = 0		--慕容复指令
	WAR.TZ_DY = 0		--段誉指令
	WAR.TZ_XZ = 0		--虚竹指令
	WAR.TZ_XZ_SSH = {}	--中了生死符的人记录
	WAR.BFX = 0			--必封穴
	WAR.BLX = 0			--必流血
	WAR.BBF = 0 		--必冰封
	WAR.BZS = 0			--必灼烧
	WAR.TXZQ = {}		--太玄之轻
	WAR.GSWS = 0 		--盖世无双
	WAR.JQSDXS = {} 	--无酒不欢：集气速度显示
	WAR.TWLJ = 0 		--天外连击
	WAR.hit_DGQB = 0	--无酒不欢：独孤求败反击的特效显示
	WAR.WXFS = nil		--李秋水无相分身的编号记录
	WAR.JJPZ = {} 		--无酒不欢：九剑破招
	WAR.TKJQ = {}		--太空卸劲减少集气
	WAR.JJZC = 0		--九剑真传的4种主动攻击特效
	WAR.JJDJ = 0 		--九剑荡剑式回气
	WAR.Dodge = 0		--判定是否闪避
	WAR.TJZX = {}		--太极之形记录
	WAR.TJZX_LJ = 0		--太极之形连击
	WAR.CXLC = 0		--狄云赤心连城
	WAR.CXLC_Count = 0	--狄云赤心连城计数
	WAR.FQY = 0			--风清扬无招胜有招
	WAR.WZSYZ = {}		--被无招胜有招击中的人
	WAR.ZXXS = {}		--紫霞蓄力
	WAR.GMYS = 0		--范遥挨打加减伤
	WAR.GMZS = {}		--被杨逍打中的人记录
	WAR.LPZ = 0			--林平之回气


	WAR.JYFX = {}		--九阳7时序解除封穴
	WAR.L_TLD = 0;		--装备屠龙刀特效，1流血
	WAR.PJTX = 0 		--玄铁剑配玄铁剑法，破尽天下
	WAR.QYBY = {}		--林朝英轻云蔽月，每50时序可触发一次，免疫伤害10时序
	WAR.XZ_YB = {}		--小昭影步记录
	WAR.LSQ = {}		--被灵蛇拳击中的人记录

	WAR.HP_Bonus_Count = {}	--记录血量翻倍的编号

	WAR.L_EffectColor = {}					--异常状态的颜色显示
	WAR.L_EffectColor[1] = M_Silver;		--显示减少生命
	WAR.L_EffectColor[2] = M_Pink;			--显示增加生命
	WAR.L_EffectColor[3] = M_LightBlue;		--显示解毒
	WAR.L_EffectColor[4] = M_DeepSkyBlue;	--显示内力减少和增加
	WAR.L_EffectColor[5] = M_PaleGreen;		--显示体力减少和增加
	WAR.L_EffectColor[6] = C_GOLD;			--显示封穴
	WAR.L_EffectColor[7] = M_Red;			--显示流血
	WAR.L_EffectColor[8] = M_DarkGreen;		--显示中毒
	WAR.L_EffectColor[9] = PinkRed;			--显示内伤减少和增加
	WAR.L_EffectColor[10] = LightSkyBlue;	--显示冰封
	WAR.L_EffectColor[11] = C_ORANGE;		--显示灼烧

	WAR.L_WNGZL = {};		--王难姑指令，持续中毒减血
	WAR.L_HQNZL = {};		--胡青牛指令，持续回血回内伤

	WAR.L_QKDNY = {};		--设定攻击多个人时，乾坤只能被反一次

	WAR.L_NOT_MOVE = {};	--记录不可移动的人
	WAR.XDLZ = {};			--记录被血刀老祖杀掉的人
	WAR.ZZRZY = 0			--周芷若领悟左右的剧情
	WAR.XTTX = 0			--先天调息

	WAR.ShowHP = 1			--血条显示

	WAR.FF = 0				--主角觉醒后，喵姐开局前三次不受伤害

	WAR.ZQHT = 0 			--是否触发真气护体
	WAR.TSSB = {}			--进阶泰山，使用后20时序内闪避
	WAR.JDYJ = {}			--剑胆琴心增加御剑能力
	WAR.WMYH = {}			--无明业火状态，耗损使用的内力一半的生命

	WAR.JHLY = {}			--无酒不欢：举火燎原，金乌+燃木+火焰刀
	WAR.LRHF = {}			--无酒不欢：利刃寒锋，修罗+阴风+沧溟

	WAR.SLSX = {}			--金轮，十龙十象
	WAR.HMZT = {}			--昏迷状态

	WAR.JYZT = {}			--阿紫，禁药状态
	WAR.MZSH = 0			--阿紫曼珠沙华，每杀一个人+200气攻气防

	WAR.SZSD = -1			--被死战锁定的目标

	WAR.CSZT = {}			--沉睡状态

	WAR.PJZT = {}			--破军状态
	WAR.PJJL = {}			--被破军前的内功记录

	WAR.YSJF = {}			--玉石俱焚

	WAR.HLZT = {}			--混乱状态

	WAR.QYZT = {}			--琴音状态

	WAR.XRZT = {}			--虚弱状态

	WAR.QGZT = {}			--倾国状态

	WAR.BXZS = 0				--辟邪招式
	WAR.BXLQ = {}				--辟邪冷却记录
	WAR.BXCD = {0,1,0,1,2,3}	--辟邪冷却时间

	WAR.KHSZ = 0			--葵花神针

	WAR.JSBM = {}			--金身不灭

	CleanWarMap(7, 0)
end


--显示人物的战斗信息，包括头像，生命，内力等
function WarShowHead(id)
	if not id then
		id = WAR.CurID
	end
	if id < 0 then
		return
	end
	local pid = WAR.Person[id]["人物编号"]
	local p = JY.Person[pid]
	local h = CC.FontSMALL
	local width = CC.FontSMALL*11 - 6
	local height = (CC.FontSMALL+CC.RowPixel)*9 - 12
	local x1, y1 = nil, nil
	local i = 1
	local size = CC.FontSmall3
	if p["主运内功"] > 0 then
		height = height + CC.FontSMALL + 2
	end
    if p["主运轻功"] > 0 then
		height = height + CC.FontSMALL + 2
	end
	if WAR.Person[id]["我方"] == true then
		x1 = CC.ScreenW - width - 6
		y1 = CC.ScreenH - height - CC.ScreenH/6 -6
		DrawBox(x1, y1, x1 + width, y1 + height + CC.ScreenH/6, C_GOLD)
	else
		x1 = 10
		y1 = 10
		DrawBox(x1, y1, x1 + width, y1 + height + CC.ScreenH/6, C_GOLD)
	end

	---------------------------------------------------------状态显示---------------------------------------------------------

	local zt_num = 0

	--神照重生显示
	if WAR.tmp[2000 + pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 1 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1, "已神照复活", C_WHITE, size)
		else
			lib.LoadPNG(98, 1 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3, "已神照复活", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--太极之形显示
	if Curr_NG(pid, 171) then
		local tjzx = WAR.TJZX[pid] or 0
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 2 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "太极之形:"..tjzx, C_WHITE, size)
		else
			lib.LoadPNG(98, 2 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "太极之形:"..tjzx, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--迷踪步显示
	if pid == 0 and JY.Person[615]["论剑奖励"] == 1 then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 3 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "迷踪步开启", C_WHITE, size)
		else
			lib.LoadPNG(98, 3 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "迷踪步开启", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--岳灵珊，慧中灵剑显示
	if match_ID(pid, 79) then
		local JF = 0
		for i = 1, CC.Kungfunum do
			if JY.Wugong[JY.Person[pid]["武功" .. i]]["武功类型"] == 3 then
				JF = JF + 1
			end
		end
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 4 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "慧中灵剑:"..JF, C_WHITE, size)
		else
			lib.LoadPNG(98, 4 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "慧中灵剑:"..JF, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--剑胆琴心显示
	if JiandanQX(pid) then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 5 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "剑胆琴心", C_WHITE, size)
		else
			lib.LoadPNG(98, 5 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "剑胆琴心", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无明业火显示	
	if WAR.WMYH[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 6 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "无明业火:"..WAR.WMYH[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 6 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "无明业火:"..WAR.WMYH[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--天衣无缝显示
	if TianYiWF(pid) then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 7 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "天衣无缝", C_WHITE, size)
		else
			lib.LoadPNG(98, 7 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "天衣无缝", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：举火燎原，金乌+燃木+火焰刀，造成引燃效果
	if WAR.JHLY[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 8 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "引燃状态:"..WAR.JHLY[pid].."时序", C_WHITE, size)
		else
			lib.LoadPNG(98, 8 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "引燃状态:"..WAR.JHLY[pid].."时序", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：利刃寒锋，修罗+阴风+沧溟，造成冻结效果
	if WAR.LRHF[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 9 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "冻结状态:"..WAR.LRHF[pid].."时序", C_WHITE, size)
		else
			lib.LoadPNG(98, 9 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "冻结状态:"..WAR.LRHF[pid].."时序", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：被死战锁定的目标
	if pid == WAR.SZSD then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 10 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "死战目标", C_WHITE, size)
		else
			lib.LoadPNG(98, 10 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "死战目标", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：金轮 十龙十象状态
	if WAR.SLSX[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 11 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "十龙十象", C_WHITE, size)
		else
			lib.LoadPNG(98, 11 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "十龙十象", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：昏迷状态
	if WAR.HMZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 12 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "昏迷状态", C_WHITE, size)
		else
			lib.LoadPNG(98, 12 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "昏迷状态", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：阿紫曼珠沙华
	if match_ID(pid, 47) then
		local tjzx = WAR.TJZX[pid] or 0
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 13 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "曼珠沙华:" .. WAR.MZSH, C_WHITE, size)
		else
			lib.LoadPNG(98, 13 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "曼珠沙华:" .. WAR.MZSH, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：阿紫禁药状态
	if WAR.JYZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 14 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "禁药状态", C_WHITE, size)
		else
			lib.LoadPNG(98, 14 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "禁药状态", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：沉睡状态
	if WAR.CSZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 15 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "沉睡状态", C_WHITE, size)
		else
			lib.LoadPNG(98, 15 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "沉睡状态", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：灭绝的玉石俱焚
	if WAR.YSJF[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 16 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "玉石俱焚:" .. WAR.YSJF[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 16 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "玉石俱焚:" .. WAR.YSJF[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：停运状态
	if WAR.PJZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 17 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "停运状态:" .. WAR.PJZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 17 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "停运状态:" .. WAR.PJZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：混乱状态
	if WAR.HLZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 18 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "混乱状态:" .. WAR.HLZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 18 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "混乱状态:" .. WAR.HLZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：琴音状态
	if WAR.QYZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 19 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "琴音" .. WAR.QYZT[pid].."层", C_WHITE, size)
		else
			lib.LoadPNG(98, 19 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "琴音" .. WAR.QYZT[pid].."层", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：虚弱状态
	if WAR.XRZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 20 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "虚弱状态:" .. WAR.XRZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 20 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "虚弱状态:" .. WAR.XRZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：倾国状态
	if WAR.QGZT[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 21 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "倾国剩余" .. WAR.QGZT[pid].."次", C_WHITE, size)
		else
			lib.LoadPNG(98, 21 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "倾国剩余" .. WAR.QGZT[pid].."次", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：盲目状态
	if WAR.KHCM[pid] == 2 then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 22 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "盲目状态", C_WHITE, size)
		else
			lib.LoadPNG(98, 22 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "盲目状态", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：葵花尊者
	if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and pid == 27 then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 23 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "葵花尊者形态", C_WHITE, size)
		else
			lib.LoadPNG(98, 23 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "葵花尊者形态", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：其疾如风
	if WAR.FLHS1 == 1 and pid == 0 then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 24 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "其疾如风", C_WHITE, size)
		else
			lib.LoadPNG(98, 24 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "其疾如风", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--无酒不欢：金身不灭
	if WAR.JSBM[pid] ~= nil then
		if WAR.Person[id]["我方"] == true then
			lib.LoadPNG(98, 25 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "金身不灭", C_WHITE, size)
		else
			lib.LoadPNG(98, 25 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "金身不灭", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end
	--------------------------------------------------------------------------------------------------------------------------

	local headw, headh = lib.GetPNGXY(1, p["头像代号"])
	local headx = (width - headw) / 2
	local heady = (CC.ScreenH/5 - headh) / 2
	--头像信息
	local headid = WAR.tmp[5000+id];
	lib.LoadPNG(1, headid*2, x1 + 1 + headx, y1 - 14 + heady, 1)
	x1 = x1 + CC.RowPixel
	y1 = y1 + CC.RowPixel + CC.ScreenH/6 - 12
	local color = nil
	if p["受伤程度"] < p["中毒程度"] then
		if p["中毒程度"] == 0 then
			color = RGB(252, 148, 16)
		elseif p["中毒程度"] < 50 then
			color = RGB(120, 208, 88)
		else
			color = RGB(56, 136, 36)
		end
	elseif p["受伤程度"] < 33 then
		color = RGB(236, 200, 40)
	elseif p["受伤程度"] < 66 then
		color = RGB(244, 128, 32)
	else
		color = RGB(232, 32, 44)
	end
	MyDrawString(x1 -4 , x1 + width -4, y1 + CC.RowPixel + 2, p["姓名"], color, CC.DefaultFont)
	--有运功时的显示
	if p["主运内功"] > 0 then
		DrawString(x1 + 8, y1 + CC.RowPixel + CC.DefaultFont, "架势", MilkWhite, size)
		DrawString(x1 + size*3, y1 + CC.RowPixel+ CC.DefaultFont, JY.Wugong[p["主运内功"]]["名称"], TG_Red_Bright, size)
		y1 = y1 + CC.FontSMALL + 2
	end
	--有轻功时的显示
	if p["主运轻功"] > 0 then
		DrawString(x1 + 8, y1 + CC.RowPixel + CC.DefaultFont, "轻功", MilkWhite, size)
		DrawString(x1 + size*3, y1 + CC.RowPixel+ CC.DefaultFont, JY.Wugong[p["主运轻功"]]["名称"], M_DeepSkyBlue, size)
		y1 = y1 + CC.FontSMALL + 2
	end
	y1 = y1 + size + CC.RowPixel + 3

	--颜色条
	local pcx = x1 + 3 - CC.RowPixel + 2;
	local pcy = y1 + CC.RowPixel +1

	--生命条
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 274 * 2);

	lib.SetClip(pcx, pcy, pcx + (p["生命"]/p["生命最大值"])*pcw, pcy + pch)
	lib.LoadPNG(1, 274 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	--内力条
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 273 * 2);
	lib.SetClip(pcx, pcy, pcx + (p["内力"]/p["内力最大值"])*pcw, pcy + pch)
	lib.LoadPNG(1, 273 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	--体力条
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 276 * 2);
	lib.SetClip(pcx, pcy, pcx + (p["体力"]/100)*pcw, pcy + pch)
	lib.LoadPNG(1, 276 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	local lifexs = "命 "..p["生命"]
	local nlxs = "内 "..p["内力"]
	local tlxs = "体 "..p["体力"]
	local lqzxs = WAR.LQZ[pid] or 0;	--怒气
	local zdxs = p["中毒程度"]

	local nsxs = p["受伤程度"];		--内伤
	local bfxs = p["冰封程度"];		--冰封
	local zsxs = p["灼烧程度"];		--灼烧
	local fxxs = WAR.FXDS[pid] or 0;		--封穴
	local lxxs = WAR.LXZT[pid] or 0;		--流血

	DrawString(x1 + 9, y1 + CC.RowPixel + 6, lifexs, M_White, CC.FontSMALL)
	DrawString(x1 + 9, y1 + CC.RowPixel + size + 11, nlxs, M_White, CC.FontSMALL)
	DrawString(x1 + 9, y1 + CC.RowPixel + 2*size + 16, tlxs, M_White, CC.FontSMALL)

	y1 = y1 + 3*(CC.RowPixel + size) + 4

  	local myx1 = 3;
  	local myy1 = 0;
	--怒气
	DrawString(x1 + myx1, y1 + myy1, "怒气", C_RED, size)
	if lqzxs == 100 then
		lqzxs = "极"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, lqzxs, C_RED, size)
	--如林
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "如林", M_DeepSkyBlue, size)
	if pid == 0 then
		DrawString(x1 + size*5/2 + myx1, y1 + myy1, WAR.FLHS2, M_DeepSkyBlue, size)
	else
		DrawString(x1 + size*5/2 + myx1, y1 + myy1, "※", M_DeepSkyBlue, size)
	end
	--冰封
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "冰封", M_LightBlue, size)
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, bfxs, M_LightBlue, size)
	--灼烧
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "灼烧", C_ORANGE, size)
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, zsxs, C_ORANGE, size)
	--封穴
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "封穴", C_GOLD, size)
	if fxxs == 50 then
		fxxs = "极"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, fxxs, C_GOLD, size)
	--流血
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "流血", M_DarkRed, size)
	if lxxs == 100 then
		lxxs = "极"
	end
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, lxxs, M_DarkRed, size)
	--内伤
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "内伤", PinkRed, size)
	if nsxs == 100 then
		nsxs = "极"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, nsxs, PinkRed, size)
	--中毒
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "中毒", LimeGreen, size)
	if zdxs == 100 then
		zdxs = "极"
	end
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, zdxs, LimeGreen, size)
	if WAR.PREVIEW < 0 then return end

	local pidq = JY.Person[WAR.PREVIEW]["轻功"]
	local eidq = JY.Person[pid]["轻功"]
	local fightnum = 1 + math.modf((pidq - eidq) / 20)
	fightnum = math.max(1, fightnum)

	local fightnum2 = 1 + math.modf((eidq - pidq) / 20)
	fightnum2 = math.max(1, fightnum2)

	local wugong = JY.Person[WAR.PREVIEW]["论剑奖励"]
	if WAR.Person[id]["我方"] == false and wugong > 0 then
		y1 = y1 + 3*(CC.RowPixel + size) +12
		DrawBox(x1-7, y1, x1 + width-7 , y1 + size*6, C_GOLD)
		DrawString(x1+2, y1 + (size + CC.RowPixel) - 18, "进攻-" .. JY.Wugong[wugong]["名称"], C_WHITE, size)
		DrawString(x1+2, y1 + 2 * (size + CC.RowPixel) - 18, "预计伤害：" .. (fightnum * War_PredictDamage(WAR.PREVIEW, pid, wugong)), C_WHITE, size)
		local wugong2 = JY.Person[pid]["主运内功"]
		if wugong2 > 0 then
			local fanjinum = War_PredictDamage(pid, WAR.PREVIEW, wugong2) * fightnum2
			DrawString(x1+2, y1 + 3 * (size + CC.RowPixel) - 18, "若被反击：" .. fanjinum, C_WHITE, size)
			DrawString(x1+2, y1 + 4 * (size + CC.RowPixel) - 18, "剩余气血：" .. (JY.Person[WAR.PREVIEW]["生命"] - fanjinum), C_WHITE, size)
		end
	end
end

function War_PredictDamage(pid, eid, wugong)
	local def = JY.Person[eid]["防御力"]
	local true_WL = get_skill_power(pid, wugong)
	local dmg = math.max(true_WL - def, 1)
	return dmg
end

function War_CalculateDamage(pid, eid, wugong)
	local def = JY.Person[eid]["防御力"]
	local true_WL = get_skill_power(pid, wugong)
	local dmg = math.max(true_WL - def, 1)
	dmg = dmg + JY.Person[eid]["受伤程度"]
	return dmg
end

--自动选择合适的武功
function War_AutoSelectWugong()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local probability = {}
	local wugongnum = CC.Kungfunum
	for i = 1, CC.Kungfunum do
		local wugongid = JY.Person[pid]["武功" .. i]
		if wugongid > 0 then
			if JY.Wugong[wugongid]["伤害类型"] == 0 then

				--选择杀生命的武功，必须消耗内力比现有内力小，起码可以发出一级的武功。
				if JY.Wugong[wugongid]["消耗内力点数"] <= JY.Person[pid]["内力"] then
					local level = math.modf(JY.Person[pid]["武功等级" .. i] / 100) + 1
					probability[i] = get_skill_power(pid, wugongid, level)	--无酒不欢：采用新公式
				else
					probability[i] = 0
				end

				--轻功不可攻击
				if JY.Wugong[wugongid]["武功类型"] == 7 then
					probability[i] = 0
				end

				--内功攻击
				if JY.Wugong[wugongid]["武功类型"] == 6 then

					if inteam(pid) == false and i == 1 then 				--NPC会用第一格内功

					elseif pid == 0 and JY.Base["畅想"] > 0 and i == 1 then --畅想会用第一格内功

					elseif wugongid == 105 and (match_ID(pid, 36) or match_ID(pid, 27))then		--林平之 东方 使用葵花神功

					elseif wugongid == 102 and match_ID(pid, 38) then		--石破天 使用太玄神功

					elseif wugongid == 106 and match_ID(pid, 9) then		--张无忌 使用九阳神功

					elseif wugongid == 94 and match_ID(pid, 37) then		--狄云 使用神经照

					elseif wugongid == 108 and match_ID(pid, 114) then		--扫地 使用易筋经

					elseif wugongid == 93 and match_ID(pid, 66) then		--小昭 使用圣火

					elseif wugongid == 104 and match_ID(pid, 60) then		--欧阳锋 使用逆运

					elseif wugongid == 103 and (match_ID(pid, 39) or match_ID(pid, 40))then		--侠客岛主 使用龙象

					elseif (pid == 0 and GetS(4, 5, 5, 5) == 5) or match_ID(pid, 48) then		--天罡 游坦之 使用内功

					else
						probability[i] = 0
					end
				end

				--斗转星移
				if wugongid == 43 and match_ID(pid, 51) == false then
					probability[i] = 0
				end

				--乔峰不用打狗
				if wugongid == 80 and pid == 50 then
					probability[i] = 0
				end

				--黄药师不用玉萧落英
				if (wugongid == 12 or wugongid == 38) and pid == 57 then
					probability[i] = 0
				end

				--周伯通不用太极拳
				if wugongid == 16 and pid == 64 then
					probability[i] = 0
				end

				--二十大欧阳锋不用逆运蛤蟆
				if (wugongid == 95 or wugongid == 104) and pid == 60 and WAR.ZDDH == 289 then
					probability[i] = 0
				end

				--七夕任盈盈不用棋书画
				if (wugongid == 72 or wugongid == 84 or wugongid == 142) and pid == 611 then
					probability[i] = 0
				end

				--七夕郭靖不用打狗
				if wugongid == 80 and pid == 612 then
					probability[i] = 0
				end

				--七夕黄蓉不用降龙
				if wugongid == 26 and pid == 613 then
					probability[i] = 0
				end

				--七夕杨过暴怒不用玄铁
				if wugongid == 45 and pid == 614 and WAR.LQZ[pid] == 100 then
					probability[i] = 0
				end

				--襄阳金轮不用龙象
				--神邪战三绝不用龙象
				--二十大不用龙象
				if wugongid == 103 and pid == 62 and (WAR.ZDDH == 275 or WAR.ZDDH == 277 or WAR.ZDDH == 289) then
					probability[i] = 0
				end

				--刀剑合璧胡一刀不用苗剑
				if wugongid == 44 and pid == 633 and WAR.ZDDH == 280 then
					probability[i] = 0
				end

				--刀剑合璧苗人凤不用胡刀
				if wugongid == 67 and pid == 3 and WAR.ZDDH == 280 then
					probability[i] = 0
				end

				--左冷禅不用其他几个五岳剑法
				if pid == 22 and (wugongid == 30 or wugongid == 31 or wugongid == 32 or wugongid == 34) then
					probability[i] = 0
				end
			else
				probability[i] = 0		 --自动不会杀内力
			end
		else
			wugongnum = i - 1
			break;
		end
	end

	if wugongnum ==  0 then			--如果没有武功，直接返回-1
		return -1;
	end

	local maxoffense = 0			--计算最大攻击力
	for i = 1, wugongnum do
		if maxoffense < probability[i] then
			maxoffense = probability[i]
		end
	end

	local mynum = 0					--计算我方和敌人个数
	local enemynum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			if WAR.Person[i]["我方"] == WAR.Person[WAR.CurID]["我方"] then
				mynum = mynum + 1
			else
				enemynum = enemynum + 1
			end
		end
	end


	local factor = 0			--敌人人数影响因子，敌人多则对线面等攻击多人武功的选择概率增加
	if mynum < enemynum then
		factor = 2
	else
		factor = 1
	end

	for i = 1, wugongnum do		--考虑其他概率效果
		local wugongid = JY.Person[pid]["武功" .. i]
		if probability[i] > 0 then
			if probability[i] < maxoffense*3/4 then		--去掉攻击力小的武功
				probability[i] = 0
			else
				local level = math.modf(JY.Person[pid]["武功等级" .. i] / 100) + 1
				probability[i] = probability[i] + JY.Wugong[wugongid]["移动范围".. level]  * factor*10
				if JY.Wugong[wugongid]["杀伤范围" .. level] > 0 then
					probability[i] = probability[i] + JY.Wugong[wugongid]["杀伤范围" .. level]* factor*10
				end
			end
		end
	end

	local s = {}			--按照概率依次累加
	local maxnum = 0
	for i = 1, wugongnum do
		s[i] = maxnum
		maxnum = maxnum + probability[i]
	end
	s[wugongnum + 1] = maxnum
	if maxnum == 0 then		--没有可以选择的武功
		return -1
	end

	local v = Rnd(maxnum)		--产生随机数
	local selectid = 0
	for i = 1, wugongnum do		--根据产生的随机数，寻找落在哪个武功区间
		if s[i] <= v and v < s[i + 1] then
			selectid = i
		end
	end
	return selectid
end

--战斗武功选择菜单
--sb star为无意义参数，仅为防止代码语法错误跳出
function War_FightMenu(sb, star, wgnum)
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local numwugong = 0
	local menu = {}
	local canuse = {}
	local c = 0;
	for i = 1, CC.Kungfunum do
		local tmp = JY.Person[pid]["武功" .. i]
		if tmp > 0 then
			menu[i] = {JY.Wugong[tmp]["名称"], nil, 1}

			--[[内功无法攻击
			--游坦之可以
			if match_ID(pid, 48) == false and JY.Wugong[tmp]["武功类型"] == 6 then
				menu[i][3] = 0
			end

			--轻功无法攻击
			if JY.Wugong[tmp]["武功类型"] == 7 then
				menu[i][3] = 0
			end

			--斗转星移不显示
			if tmp == 43 then
				menu[i][3] = 0
			end]]

			numwugong = numwugong + 1

			if menu[i][3] == 1 then
				c = c + 1
				canuse[c] = i
			end
		end
	end
	if c == 0 then
		return 0
	end
	if wgnum == nil then
		local r = nil
		r = ShowMenu(menu, numwugong, 0, CC.MainSubMenuX + 15, CC.MainSubMenuY, 0, 0, 1, 1, CC.DefaultFont, C_ORANGE, C_WHITE)
		if r == 0 then
			return 0
		end
		--为了伤害预览添加论剑奖励作为标记
		WAR.PREVIEW = pid
		JY.Person[pid]["论剑奖励"] = JY.Person[pid]["武功" .. r]
		WAR.ShowHead = 0
		local r2 = War_Fight_Sub(WAR.CurID, r)
		WAR.PREVIEW = -1
		WAR.ShowHead = 1
		Cls()
		return r2
	--无酒不欢：数字快捷键直接使用武功
	else
		if wgnum <= c then
			WAR.PREVIEW = pid
			JY.Person[pid]["论剑奖励"] = JY.Person[pid]["武功" .. canuse[wgnum]]
			WAR.ShowHead = 0
			local r2 = War_Fight_Sub(WAR.CurID, canuse[wgnum])
			WAR.PREVIEW = -1
			WAR.ShowHead = 1
			Cls()
			return r2
		else
			return 0
		end
	end
end

--自动战斗时 做思考
--吃药的flag：2 生命；3内力；4体力；6 解毒
function War_Think()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local r = -1
	local minNeili = War_GetMinNeiLi(pid)
	local can_eat_drug = 0
	--非我方，会考虑吃药
	if WAR.Person[WAR.CurID]["我方"] == false then
		can_eat_drug = 1
	--如果是我方，只有在队且允许才会吃药
	else
		if inteam(pid) and JY.Person[pid]["是否吃药"] == 1 then
			can_eat_drug = 1
		end
	end
	--侠客正岛主战不吃药
	if WAR.Person[WAR.CurID]["我方"] == false and WAR.ZDDH == 257 then
		can_eat_drug = 0
	end
	--可以吃药的话
	if can_eat_drug == 1 then
		--吃体力药
		local eat_eng_drug = 0
		if inteam(pid) then
			local fz = {50, 30, 10}
			if JY.Person[pid]["体力"] < fz[JY.Person[pid]["体力阈值"]] then
				eat_eng_drug = 1
			end
		else
			if JY.Person[pid]["体力"] < 10 then
				eat_eng_drug = 1
			end
		end
		if eat_eng_drug == 1 then
			r = War_ThinkDrug(4)
			if r >= 0 then
			  return r
			end
			return 0
		end

		--吃血药
		local eat_hp_drug = 0
		if inteam(pid) then
			local fz = {0.7, 0.5, 0.3}
			if JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"]*fz[JY.Person[pid]["生命阈值"]] then
				eat_hp_drug = 1
			end
		else
			--根据生命确定吃血药几率
			local rate = -1
			if JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 5 then
				rate = 90
			elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 4 then
				rate = 70
			elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 3 then
				rate = 50
			elseif JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 2 then
				rate = 25
			end

			--内伤也增加吃血药几率
			if JY.Person[pid]["受伤程度"] > 50 then
				rate = rate + 50
			end

			--暴气时，不吃药
			if Rnd(100) < rate and WAR.LQZ[pid] ~= nil and WAR.LQZ[pid] ~= 100 then
				eat_hp_drug = 1
			end
		end
		if eat_hp_drug == 1 then
			r = War_ThinkDrug(2)
			if r >= 0 then				--如果有药吃药
				return r
			else
				r = War_ThinkDoctor()		--如果没有药，考虑医疗
				if r >= 0 then
					return r
				end
			end
		end

		--吃内力药
		local eat_mp_drug = 0
		if inteam(pid) then
			local fz = {0.7, 0.5, 0.3}
			if JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"]*fz[JY.Person[pid]["内力阈值"]] then
				eat_mp_drug = 1
			end
		else
			--考虑内力
			local rate = -1
			if JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 6 then
				rate = 100
			elseif JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 5 then
				rate = 75
			elseif JY.Person[pid]["内力"] < JY.Person[pid]["内力最大值"] / 4 then
				rate = 50
			end

			if Rnd(100) < rate or minNeili > JY.Person[pid]["内力"] then
				eat_mp_drug = 1
			end
		end
		if eat_mp_drug == 1 then
			r = War_ThinkDrug(3)
			if r >= 0 then
				return r
			end
		end

		local jdrate = -1
		if CC.PersonAttribMax["中毒程度"] * 3 / 4 < JY.Person[pid]["中毒程度"] then
			jdrate = 60
		else
			if CC.PersonAttribMax["中毒程度"] / 2 < JY.Person[pid]["中毒程度"] then
				jdrate = 30
			end
		end

		--半血以下吃解毒药
		--暴怒不吃解毒药
		if Rnd(100) < jdrate and JY.Person[pid]["生命"] < JY.Person[pid]["生命最大值"] / 2 and WAR.LQZ[pid] ~= nil and WAR.LQZ[pid] ~= 100 then
			r = War_ThinkDrug(6)
			if r >= 0 then
				return r
			end
		end
	end

	if inteam(pid) then
		if JY.Person[pid]["行为模式"] == 4 then
			r = 0
		elseif JY.Person[pid]["行为模式"] == 3 then
			r = 7
		elseif JY.Person[pid]["行为模式"] == 2 then
			r = 8
		elseif JY.Person[pid]["行为模式"] == 1 then
			if minNeili <= JY.Person[pid]["内力"] and JY.Person[pid]["体力"] > 10 then
				r = 1
			else
				r = 0
			end
		end
	else
		if minNeili <= JY.Person[pid]["内力"] and JY.Person[pid]["体力"] > 10 then
			r = 1
		else
			r = 0
		end
	end
	return r
end

--自动攻击
function War_AutoFight()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local wugongnum;
	if inteam(pid) and JY.Person[pid]["优先使用"] ~= 0 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["武功"..i] == JY.Person[pid]["优先使用"] then
				wugongnum = i
				break
			end
		end
		--加一条防止被洗掉等意外
		if wugongnum == nil then
			wugongnum = War_AutoSelectWugong()
		end
	else
		wugongnum = War_AutoSelectWugong()
	end
	if wugongnum <= 0 then
		War_AutoEscape()
		War_RestMenu()
		return
	end
	AIThink(wugongnum)
end

--自动战斗
function War_Auto()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	WAR.ShowHead = 1
	WarDrawMap(0)
	ShowScreen()
	lib.Delay(CC.WarAutoDelay)
	WAR.ShowHead = 0
	if CC.AutoWarShowHead == 1 then
		WAR.ShowHead = 1
	end
	local autotype = War_Think()

	if autotype == 0 then
		War_AutoEscape()
		War_RestMenu()
	elseif autotype == 1 then
		War_AutoFight()
	elseif autotype == 2 then
		War_AutoEscape()
		War_AutoEatDrug(2)
	elseif autotype == 3 then
		War_AutoEscape()
		War_AutoEatDrug(3)
	elseif autotype == 4 then
		War_AutoEscape()
		War_AutoEatDrug(4)
	elseif autotype == 5 then
		War_AutoEscape()
		War_AutoDoctor()
	elseif autotype == 6 then
		War_AutoEscape()
		War_AutoEatDrug(6)
	elseif autotype == 7 then
		War_RestMenu()
	elseif autotype == 8 then
		War_DefupMenu()
	end
	return 0
end

--人物升级
function War_AddPersonLVUP(pid)
	local tmplevel = JY.Person[pid]["等级"]
	if CC.Level <= tmplevel then
		return false
	end
	if JY.Person[pid]["经验"] < CC.Exp[tmplevel] then
		return false
	end
	while CC.Exp[tmplevel] <= JY.Person[pid]["经验"] do
		tmplevel = tmplevel + 1
		if CC.Level <= tmplevel then
			break;
		end
	end

	DrawStrBoxWaitKey(string.format("%s 升级了", JY.Person[pid]["姓名"]), C_WHITE, CC.DefaultFont)
	--计算提升的等级
	local leveladd = tmplevel - JY.Person[pid]["等级"]

	JY.Person[pid]["等级"] = JY.Person[pid]["等级"] + leveladd

	--提高生命增长
	AddPersonAttrib(pid, "生命最大值", (JY.Person[pid]["生命增长"] + 4) * leveladd * 4)

	JY.Person[pid]["生命"] = JY.Person[pid]["生命最大值"]
	JY.Person[pid]["体力"] = CC.PersonAttribMax["体力"]
	JY.Person[pid]["受伤程度"] = 0
	JY.Person[pid]["中毒程度"] = 0

	local theadd = JY.Person[pid]["资质"] / 4
	--聪明人内力加少。。。
	--增加内力的成长
	AddPersonAttrib(pid, "内力最大值", math.modf(leveladd * ((16 - JY.Person[pid]["生命增长"]) * 7 + 210 / (theadd + 1))))

	--天罡内力每级额外加50
	if pid == 0 and JY.Base["标准"] == 6 then
	  AddPersonAttrib(pid, "内力最大值", 50 * leveladd)
	end
	JY.Person[pid]["内力"] = JY.Person[pid]["内力最大值"]

	--循环提升等级，累加属性
	for i = 1, leveladd do
		local ups;
		local p_zz = JY.Person[pid]["资质"];
		if p_zz <= 15 then
			ups = 2
		elseif p_zz >= 16 and p_zz <= 30 then
			ups = 3
		elseif p_zz >= 31 and p_zz <= 45 then
			ups = 4
		elseif p_zz >= 46 and p_zz <= 60 then
			ups = 5
		elseif p_zz >= 61 and p_zz <= 75 then
			ups = 6
		elseif p_zz >= 76 and p_zz <= 90 then
			ups = 7
		elseif p_zz >= 91 then
			ups = 8
		end

		--令狐冲 内伤回复前，每级3点
		--[[
		if pid == 35 and GetD(82, 1, 0) == 1 then
			ups = 3
		end]]

		--队友郭靖 20级之后，每级6点
		if pid == 55 and JY.Person[pid]["等级"] > 20 then
			ups = 6
		end

		AddPersonAttrib(pid, "攻击力", ups)
		AddPersonAttrib(pid, "防御力", ups)
		AddPersonAttrib(pid, "轻功", ups)

		--修复医疗、用毒、解毒能力不与等级挂钩的问题
		if JY.Person[pid]["医疗能力"] >= 20 then
			AddPersonAttrib(pid, "医疗能力", 2)
		end
		if JY.Person[pid]["用毒能力"] >= 20 then
			AddPersonAttrib(pid, "用毒能力", 2)
		end
		if JY.Person[pid]["解毒能力"] >= 20 then
			AddPersonAttrib(pid, "解毒能力", 2)
		end

		--队友陈家洛 升级加五围
		if pid == 75 then
			if JY.Person[pid]["拳掌功夫"] >= 0 then
				AddPersonAttrib(pid, "拳掌功夫", (4 + math.random(0,1)))
			end
			if JY.Person[pid]["指法技巧"] >= 0 then
				AddPersonAttrib(pid, "指法技巧", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["御剑能力"] >= 0 then
				AddPersonAttrib(pid, "御剑能力", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["耍刀技巧"] >= 0 then
				AddPersonAttrib(pid, "耍刀技巧", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["特殊兵器"] >= 0 then
				AddPersonAttrib(pid, "特殊兵器", (7 + math.random(0,1)))
			end
		end

		--暗器每级提高
		if JY.Person[pid]["暗器技巧"] >= 20 then
			AddPersonAttrib(pid, "暗器技巧", 2)
		end
	end

	local ey = 0  --每级的自由点数

	local n = ey*leveladd;		--计算随机额外点数

	--加点
	local gj = JY.Person[pid]["攻击力"];
	local fy = JY.Person[pid]["防御力"];
	local qg = JY.Person[pid]["轻功"];
	local tmpN = n;

	--天赋ID
	local tfid;
	--主角
	if pid == 0 then
		--标主
		if JY.Base["标准"] > 0 then
			tfid = 280 + JY.Base["标准"]
		--特殊
		elseif JY.Base["特殊"] > 0 then
			tfid = 290
		--畅想
		else
			tfid = JY.Base["畅想"]
		end
	--队友
	else
		tfid = pid
	end

	--升级加点界面
	local current = 1
	while true do
		if JY.Restart == 1 then
			break
		end
		Cls();
		ShowPersonStatus_sub(pid, 1, 1, tfid, -17, 1)
		DrawString(CC.ScreenW/2-CC.Fontsmall*6-2,20,string.format("可分配点数：%d 点",tmpN) ,C_ORANGE, CC.Fontsmall);
		for i = 1, 3 do
			local shade_color = C_GOLD
			if i ==  current then
				shade_color = PinkRed
			end
			DrawString(CC.ScreenW/2-CC.Fontsmall*7, 24+i*(CC.FontSmall4+CC.PersonStateRowPixel), "→",shade_color, CC.Fontsmall);
		end
		ShowScreen()
		local keypress, ktype, mx, my = WaitKey()
		--lib.Delay(CC.Frame)
		if ktype == 1 then
			if keypress == VK_UP then
				current = current - 1
				if current < 1 then
					current = 3
				end
			elseif keypress == VK_DOWN then
				current = current + 1
				if current > 3 then
					current = 1
				end
			elseif keypress == VK_LEFT and tmpN < n then
				if current == 1 and JY.Person[pid]["攻击力"] > gj then
					JY.Person[pid]["攻击力"] = JY.Person[pid]["攻击力"]-1
					tmpN = tmpN+1
				elseif current == 2 and JY.Person[pid]["防御力"] > fy then
					JY.Person[pid]["防御力"] = JY.Person[pid]["防御力"]-1
					tmpN = tmpN+1
				elseif current == 3 and JY.Person[pid]["轻功"] > qg then
					JY.Person[pid]["轻功"] = JY.Person[pid]["轻功"]-1
					tmpN = tmpN+1
				end
			elseif keypress == VK_RIGHT and tmpN > 0 then
				if current == 1 and JY.Person[pid]["攻击力"] < 520 then
					JY.Person[pid]["攻击力"] = JY.Person[pid]["攻击力"]+1
					tmpN = tmpN-1
				elseif current == 2 and JY.Person[pid]["防御力"] < 520 then
					JY.Person[pid]["防御力"] = JY.Person[pid]["防御力"]+1
					tmpN = tmpN-1
				elseif current == 3 and JY.Person[pid]["轻功"] < 520 then
					JY.Person[pid]["轻功"] = JY.Person[pid]["轻功"]+1
					tmpN = tmpN-1
				end
			elseif keypress==VK_SPACE or keypress==VK_RETURN then
				if tmpN == 0 or (JY.Person[pid]["攻击力"] == 520 and JY.Person[pid]["防御力"] == 520 and JY.Person[pid]["轻功"] == 520) then
					Cls();
					break
				else
					DrawStrBoxWaitKey("对不起，"..JY.Person[pid]["姓名"].."还有剩余的点数没加!", C_WHITE, CC.DefaultFont)
				end
			end
		end
	end
	return true
end

--战斗结束处理函数
--isexp 经验值
--warStatus 战斗状态
function War_EndPersonData(isexp, warStatus)
	--无酒不欢：血量还原函数
	Health_in_Battle_Reset()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["人物编号"]
		if WAR.Person[i]["我方"] == true and inteam(pid) then
			if WAR.Person[i]["死亡"] == false then
				WarReward(pid, WAR.ZDDH)
			elseif JY.Base["难度"] > 1 then
				JY.Person[pid]["生命最大值"] = 0
				JY.Person[pid]["内力最大值"] = 0
				JY.Person[pid]["生命"] = 0
				JY.Person[pid]["内力"] = 0
			end
		end
	end

	--无酒不欢：战后状态恢复
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["人物编号"]
		--敌方回复满状态
		if not instruct_16(pid) then
			JY.Person[pid]["生命"] = JY.Person[pid]["生命最大值"]
			JY.Person[pid]["内力"] = JY.Person[pid]["内力最大值"]
			JY.Person[pid]["体力"] = CC.PersonAttribMax["体力"]
			JY.Person[pid]["受伤程度"] = 0
			JY.Person[pid]["中毒程度"] = 0
			JY.Person[pid]["冰封程度"] = 0
			JY.Person[pid]["灼烧程度"] = 0
		--我方恢复状态
		else
			JY.Person[pid]["生命"] = JY.Person[pid]["生命最大值"]
			JY.Person[pid]["内力"] = JY.Person[pid]["内力最大值"]
			JY.Person[pid]["体力"] = CC.PersonAttribMax["体力"]
			JY.Person[pid]["受伤程度"] = 0
			JY.Person[pid]["中毒程度"] = 0
			JY.Person[pid]["冰封程度"] = 0
			JY.Person[pid]["灼烧程度"] = 0
			--如果有运功，则停止
			--[[
			if JY.Person[pid]["主运内功"] ~= 0 then
				JY.Person[pid]["主运内功"] = 0
			end
			if JY.Person[pid]["主运轻功"] ~= 0 then
				JY.Person[pid]["主运轻功"] = 0
			end]]
			--出战统计
			JY.Person[pid]["出战"] = JY.Person[pid]["出战"] + 1
		end
	end

	--乔峰武功回复
	JY.Person[50]["武功1"] = 26
	JY.Wugong[13]["名称"] = "铁掌"

	--鸠摩智武功恢复
	if JY.Base["畅想"] == 103 then
		JY.Person[0]["武功2"] = 98
	end

	--破丐帮打狗阵
	if WAR.ZDDH == 82 then
		SetS(10, 0, 18, 0, 1)
	end

	--梅庄 秃笔翁战斗后
	if WAR.ZDDH == 44 then
		instruct_3(55, 6, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
		instruct_3(55, 7, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

	--梅庄 黑白子战斗
	if WAR.ZDDH == 45 then
		instruct_3(55, 9, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

	--梅庄 黄钟公战斗
	if WAR.ZDDH == 46 then
		instruct_3(55, 13, 0, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

  	--葵花尊者战斗胜利
	--用东方的品德记录
	if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and warStatus == 1 then
		JY.Person[27]["品德"] = 10
	end

	--战斗失败，并且无经验
	if warStatus == 2 and isexp == 0 then
		return
	end

	--统计活的人数
	local liveNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["我方"] == true and JY.Person[WAR.Person[i]["人物编号"]]["生命"] > 0 then
			liveNum = liveNum + 1
		end
	end

	--青城四秀
	if WAR.ZDDH == 48 then
		SetS(57, 52, 29, 1, 0)
		SetS(57, 52, 30, 1, 0)
	--一灯居，欧阳锋，裘千刃
	elseif WAR.ZDDH == 175 then
		instruct_3(32, 12, 1, 0, 0, 0, 0, 0, 0, 0, -2, -2, -2)
	--破打狗阵
	elseif WAR.ZDDH == 82 then
		SetS(10, 0, 18, 0, 1)
	--木人巷
	elseif WAR.ZDDH == 214 then
		SetS(10, 0, 19, 0, 1)
	end

	if JY.Restart == 1 then
		return
	end
end
--孤注一掷
function IsAlone(id)
	local alone = true
	for j = 0, WAR.PersonNum - 1 do
		if j ~= id and WAR.Person[j]["我方"] == WAR.Person[id]["我方"] and WAR.Person[j]["死亡"] == false then
			alone = false
		end
	end
	return alone
end
	
--执行战斗，自动和手动战斗都调用
--id战斗人物编号
--wugongnum 使用的武功在位置
--x,y为战斗场景坐标
function War_Fight_Sub(id, wugongnum, x, y)
	local pid = WAR.Person[id]["人物编号"]
	local wugong = 0
	--JY.Person[pid]["姓名"] = wugongnum
	if wugongnum < 100 then
		wugong = JY.Person[pid]["武功" .. wugongnum]
	else
		wugong = wugongnum - 100
		--x = WAR.Person[WAR.CurID]["坐标X"] - x
		--y = WAR.Person[WAR.CurID]["坐标Y"] - y
		WarDrawMap(0)
		local fj = JY.Wugong[wugong]["名称"] .. "-反击"		

		for i = 1, 20 do
			DrawStrBox(-1, 24, fj, C_ORANGE, 10 + i)
			ShowScreen()
			if i == 20 then
				lib.Delay(240)
			else
				lib.Delay(10)
			end
		end
	end

	WAR.WGWL = JY.Wugong[wugong]["攻击力10"]
	local fightscope = JY.Wugong[wugong]["攻击范围"]		--没啥用的玩意
	local kfkind = JY.Wugong[wugong]["武功类型"]
	local level = 11   

	WAR.ShowHead = 0
	local m1, m2, m3, a1, a2 = WugongArea(wugong, level)  --获取武功的范围
	if GetWarMap(WAR.Person[id]["坐标X"], WAR.Person[id]["坐标Y"], 6) == 2 then
		a1 = 3
		a2 = a2 + 1
	end --红色
	
	if IsAlone(id) then
		a1 = 3
		a2 = a2 + 1
	end
	local movefanwei = {m1, m2, m3}				--可移动的范围
	local atkfanwei = {a1, a2}	--攻击范围

	x, y = War_FightSelectType(movefanwei, atkfanwei, x, y, wugong)

	if x == nil then
		return 0
	end

	--判断合击
	local ZHEN_ID = -1

	--攻击次数
	local fightnum = 1
	WAR.ACT = 1
	WAR.FLHS6 = 0	--如雷数量

	local emeny = GetWarMap(x, y, 2)
	if emeny >= 0 and emeny ~= WAR.CurID then
		local pidq = JY.Person[pid]["轻功"]
		local ljid = WAR.Person[emeny]["人物编号"]
		local eidq = JY.Person[ljid]["轻功"]
		fightnum = 1 + math.modf((pidq - eidq) / 20)
		fightnum = math.max(1, fightnum)
	end
	--判定左右
	if JY.Person[pid]["左右互搏"] == 1 and WAR.ZYHB == 0 then
		--判断左右，80-资质
		local zyjl = 80 - JY.Person[pid]["资质"]
		if zyjl < 0 then
			zyjl = 0
		end
		--周伯通100%
		if match_ID(pid, 64) then
			zyjl = 100
		end
		--郭靖80%
		if match_ID(pid, 55) then
			zyjl = 80
		end
		--小龙女70%
		if match_ID(pid, 59) then
			zyjl = 70
		end
		--周芷若觉醒后，70%
		if match_ID_awakened(pid, 631, 1) then
			zyjl = 70
		end
		--七夕郭靖100%
		--七夕龙女100%
		if match_ID(pid, 612) or match_ID(pid, 615) then
			zyjl = 100
		end
		--暴怒必左右
		if WAR.LQZ[pid] == 100 then
			zyjl = 100
		end
		--论剑打赢周伯通奖励+20%
		if pid == 0 and JY.Person[64]["论剑奖励"] == 1 then
			zyjl = zyjl + 20
		end
		--上限100%
		if zyjl > 100 then
			zyjl = 100
		end
		--斗转星移不触发左右
		if JLSD(0, zyjl, pid) and WAR.DZXY == 0 then
			WAR.ZYHB = 1
			--改到特效文字4显示
			if WAR.Person[WAR.CurID]["特效文字4"] ~= nil then
				WAR.Person[WAR.CurID]["特效文字4"] = WAR.Person[WAR.CurID]["特效文字4"] .."·左右互搏";
			else
				WAR.Person[WAR.CurID]["特效文字4"] = "左右互搏";
			end
		end
	end

	--周伯通触发一次左右后，有几率根据资质追加第二次左右，畅想专属
	if match_ID(pid, 64) and pid == 0 and WAR.ZYHB == 2 and WAR.ZHB == 0 then
		local zyjl = 80 - JY.Person[pid]["资质"]
		if zyjl < 0 then
			zyjl = 0
		end
		--斗转星移不触发左右
		if JLSD(0, zyjl, pid) and WAR.DZXY == 0 then
			WAR.ZYHB = 1
			WAR.ZHB = 1

			--改到特效文字4显示
			if WAR.Person[WAR.CurID]["特效文字4"] ~= nil then
				WAR.Person[WAR.CurID]["特效文字4"] = WAR.Person[WAR.CurID]["特效文字4"] .."·左右互搏";
			else
				WAR.Person[WAR.CurID]["特效文字4"] = "左右互搏";
			end
		end
	end

	--[[斗转1次
	if WAR.DZXY == 1 then
		fightnum = 1
	end]]

  while WAR.ACT <= fightnum do
	if JY.Restart == 1 then
		break
	end
	lib.GetKey()
    if WAR.WS == 1 then		--误伤
		WAR.WS = 0
    end
    if WAR.BJ == 1 then		--暴击
		WAR.BJ = 0
    end
    if WAR.DJGZ == 1 then	--刀剑归真
		WAR.DJGZ = 0
    end
    if WAR.HQT == 1 then	--霍青桐 杀体力
		WAR.HQT = 0
    end
    if WAR.CY == 1 then		--程英 杀内力
		WAR.CY = 0
    end
    if WAR.HDWZ == 1 then	--霍都随机上毒
		WAR.HDWZ = 0
    end

    WAR.NGJL = 0		--当前加力内功编号
    WAR.KHBX = 0		--葵花刺目
    WAR.LXZQ = 0
	WAR.LXYZ = 0
    WAR.GCTJ = 0
    WAR.ASKD = 0
    WAR.JSYX = 0
    WAR.BMXH = 0
    WAR.TD = -1
	WAR.TDnum = 0
    WAR.TZ_XZ = 0		--虚竹指令
    WAR.JGZ_DMZ = 0		--达摩掌
    WAR.LHQ_BNZ = 0		--般若掌
	WAR.WD_CLSZ = 0		--赤练神掌
	WAR.TXZQ = {}		--太玄之轻清除记录
    CleanWarMap(4, 0)

    WAR.L_TLD = 0		--装备屠龙刀特效，流血
	WAR.PJTX = 0 		--玄铁剑配玄铁剑法，破尽天下
	WAR.CXLC = 0		--狄云赤心连城
	WAR.FQY = 0			--风清扬无招胜有招

	WAR.YTML = 0 		--毒王大招
	WAR.JSTG = 0		--天罡大招
	WAR.TXZZ = 0		--太玄之重
	WAR.MMGJ = 0		--盲目攻击
	WAR.JSAY = 0		--金蛇奥义
	WAR.OYFXL = 0 		--欧阳锋根据蛤蟆蓄力增加伤害
	WAR.XDLeech = 0		--血刀吸血量
	WAR.WYXLeech = 0	--韦一笑吸血量
	WAR.TMGLeech = 0	--天魔功吸血量
	WAR.XHSJ = 0		--血河神鉴吸血量
	WAR.KMZWD = 0 		--周伯通空明之武道
	WAR.LFHX = 0 		--林朝英流风回雪
	WAR.YNXJ = 0		--夭矫空碧
	WAR.HXZYJ = 0		--会心之一击
	WAR.YYBJ = 0 		--郭靖：有余不尽
	WAR.NGXS = 0		--内功攻击的系数
	WAR.TYJQ = 0		--阿青天元剑气
	WAR.OYK = 0 		--欧阳克灵蛇拳
	WAR.JQBYH = 0		--六脉：剑气碧烟横
	WAR.LPZ = 0			--林平之回气

	WAR.QQSH1 = 0		--琴棋书画之持瑶琴
	WAR.QQSH2 = 0		--琴棋书画之妙笔丹青
	WAR.QQSH3 = 0		--琴棋书画之倚天屠龙功

	WAR.CMDF = 0		--沧溟刀法

	WAR.HTS = 0			--何铁手五毒随机2-5倍威力
	WAR.YZQS = 0		--一震七伤

	WAR.JJZC = 0		--九剑真传的4种主动攻击特效，攻击后会清0

    WAR.L_QKDNY = {}	--重新计算乾坤大挪移是否被反弹过
	WAR.TXXS = {} 		--特效点数显示

    WarDrawAtt(x, y, atkfanwei, 3)
    if ZHEN_ID >= 0 then
		local tmp_id = WAR.CurID
		WAR.CurID = ZHEN_ID
		WarDrawAtt(WAR.Person[ZHEN_ID]["坐标X"] + x0 - x, WAR.Person[ZHEN_ID]["坐标Y"] + y0 - y, atkfanwei, 3)
		WAR.CurID = tmp_id
    end

	local ng = 0

	--如果暴击
    if WAR.BJ == 1 then
		WAR.Person[id]["特效动画"] = 89		--暴击特效动画
		if match_ID(pid, 50) then			--乔峰特效文字
			local r = nil
			r = math.random(3)
			if r == 1 then
				Set_Eff_Text(id,"特效文字1","教单于折箭 六军辟易 奋英雄怒");
			elseif r == 2 then
				Set_Eff_Text(id,"特效文字1","虽万千人吾往矣");
			elseif r == 3 then
				Set_Eff_Text(id,"特效文字1","胡汉恩仇 须倾英雄泪");
			end
		end
		--改成特效文字4显示
		if WAR.Person[WAR.CurID]["特效文字4"] ~= nil then
			WAR.Person[WAR.CurID]["特效文字4"] = WAR.Person[WAR.CurID]["特效文字4"] .."·".. "暴击"
		else
			WAR.Person[WAR.CurID]["特效文字4"] = "暴击";
		end
    end

	--蟾震九天，斗转不触发
	if PersonKF(pid, 95) and WAR.DZXY == 0 then
		if WAR.tmp[200 + pid] == nil then
			WAR.tmp[200 + pid] = 0
		elseif WAR.tmp[200 + pid] > 100 then
			ng = ng + WAR.tmp[200 + pid] * 10 + 1500

			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].. "·蟾震九天"
			else
				WAR.Person[id]["特效文字3"] = "蟾震九天"
			end
			--欧阳锋提高伤害
			if match_ID(pid, 60) then
				WAR.OYFXL = WAR.tmp[200 + pid]
			end
			WAR.Person[id]["特效动画"] = math.fmod(95, 10) + 85

			--蓄力清0
			WAR.tmp[200 + pid] = 0
		end
	end

	--天赋外功提高100点气攻
	if Given_WG(pid, wugong) then
		ng = ng + 100
	end

    --无酒不欢：狮子吼
    if PersonKF(pid, 92) then
    	if WAR.Person[id]["特效动画"] == -1 then
    		WAR.Person[id]["特效动画"] = math.fmod(92, 10) + 85
    	end
    	local nl = JY.Person[pid]["内力"];
    	local f = 0;
		local chance = 70
		local force = 100
		--主运提高效果
		if Curr_NG(pid, 92) then
			chance = 100
			force = 200
		end
		--一般人需要内力差大于2000，而谢逊只要内力差大于0即可
		local neilicha = 2000
		if match_ID(pid, 13) then
			neilicha = 0
		end
		if math.random(100) <= chance or wugong == 92 then
			f = 1
		end
		if f == 1 then
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[j]["死亡"] == false and (nl - JY.Person[WAR.Person[j]["人物编号"]]["内力"]) > neilicha then
					WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - force
					if Curr_NG(pid, 92) then
						JY.Person[WAR.Person[j]["人物编号"]]["受伤程度"] = JY.Person[WAR.Person[j]["人物编号"]]["受伤程度"] + math.random(5, 9)
					end
				end
			end
			Set_Eff_Text(id,"特效文字2","狮子吼");
		end
    end

    --六如的风火雷
	if pid==0 and JY.Person[pid]["六如觉醒"] > 0  then
    	local rate = limitX(math.modf(20 + (101-JY.Person[pid]["资质"])/10 + JY.Person[pid]["实战"]/50 + JY.Person[pid]["攻击力"]/40 + JY.Person[pid]["武学常识"]/10),0,100);
    	local low = 25;

    	--天书数量增加几率
		low = low - JY.Base["天书数量"]

		local rf = 0
		local rh = 0
		local rl = 0
		local times = 1
		--仁者二次判定+循环两次，即一次可以触发两种六如特效
		if JY.Base["标准"] == 7 then
			times = 2
		end
		for i = 1, times do
			if JLSD(low, rate, pid) or (JY.Base["标准"] == 7 and JLSD(low, rate, pid)) then
				local lr = math.random(3)
				if lr == 1 then
					rf = 1
				elseif lr == 2 then
					rh = 1
				elseif lr == 3 then
					rl = 1
				end
			end
		end

		--其疾如风
    	if rf == 1 and JY.Base["天书数量"] >= 9 then
			WAR.Person[id]["特效动画"] = 6
			Set_Eff_Text(id,"特效文字2","其疾如风");
			WAR.FLHS1 = 1
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] == WAR.Person[WAR.CurID]["我方"] then
					WAR.Person[j].Time = WAR.Person[j].Time + 100
				end
				if WAR.Person[j].Time > 980 then
					WAR.Person[j].Time = 980
				end
			end
		end
		--侵略如火
		if rh == 1 then
			WAR.Person[id]["特效动画"] = 6
			Set_Eff_Text(id,"特效文字2","侵略如火");
			ng = ng + 3000
		end
		--动如雷震
		if rl == 1 and JY.Person[pid]["六如觉醒"] == 2 and WAR.FLHS6 < 3 then
			WAR.Person[id]["特效动画"] = 6
			Set_Eff_Text(id,"特效文字2","动如雷震");
			fightnum = fightnum + 1
			WAR.FLHS6 = WAR.FLHS6 + 1
    	end
    end

    --如果学会北冥神功
    if (PersonKF(pid, 85) and JLSD(45, 75, pid)) or (Curr_NG(pid, 85) and JLSD(20, 70, pid)) then
		if WAR.Person[id]["特效动画"] == -1 then
			WAR.Person[id]["特效动画"] = math.fmod(85, 10) + 85
		end
		Set_Eff_Text(id,"特效文字2","北冥神功");
		WAR.BMXH = 1

		--北冥神功升级
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["武功" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["武功" .. w] == 85 then
				JY.Person[pid]["武功等级" .. w] = JY.Person[pid]["武功等级" .. w] + 50
				if JY.Person[pid]["武功等级" .. w] > 999 then
					JY.Person[pid]["武功等级" .. w] = 999
				end
				break;
			end
		end
    end

    --吸星大法，与北冥不可同时触发
    if ((PersonKF(pid, 88) and JLSD(45, 75, pid)) or (Curr_NG(pid, 88) and JLSD(20, 70, pid))) and WAR.BMXH == 0 then
		if WAR.Person[id]["特效动画"] == -1 then
			WAR.Person[id]["特效动画"] = math.fmod(88, 10) + 85
		end
		Set_Eff_Text(id,"特效文字2","吸星大法");
		WAR.BMXH = 2

		--吸星大法升级
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["武功" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["武功" .. w] == 88 then
				JY.Person[pid]["武功等级" .. w] = JY.Person[pid]["武功等级" .. w] + 50
				if JY.Person[pid]["武功等级" .. w] > 999 then
					JY.Person[pid]["武功等级" .. w] = 999
				end
				break;
			end
		end
    end

    --化功大法
    if ((PersonKF(pid, 87) and JLSD(45, 75, pid)) or (Curr_NG(pid, 87) and JLSD(20, 70, pid))) and WAR.BMXH == 0 then
		if WAR.Person[id]["特效动画"] == -1 then
			WAR.Person[id]["特效动画"] = math.fmod(87, 10) + 85
		end
		Set_Eff_Text(id,"特效文字2","化功大法");
		WAR.BMXH = 3

		--化功大法升级
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["武功" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["武功" .. w] == 87 then
				JY.Person[pid]["武功等级" .. w] = JY.Person[pid]["武功等级" .. w] + 50
				if JY.Person[pid]["武功等级" .. w] > 999 then
					JY.Person[pid]["武功等级" .. w] = 999
				end
				break;
			end
		end
    end

	--蒙哥，气攻+2000点
	if pid == 627 then
		ng = ng + 2000
	end

    --乔峰
    if match_ID(pid, 50) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 1000
		if not inteam(pid) then
			ng = ng + 1000
		end
		WAR.Person[id]["特效动画"] = 111
		if WAR.Person[id]["特效文字2"] ~= nil then
			WAR.Person[id]["特效文字2"] = WAR.Person[id]["特效文字2"].."+擒龙功"
		else
			WAR.Person[id]["特效文字2"] = "擒龙功加力"
		end
    end

	--鸠摩智
	if match_ID(pid, 103) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = math.fmod(98, 10) + 85
		Set_Eff_Text(id, "特效文字2", "明王真气")
	end

	--brolycjw: 洪七公
    if match_ID(pid, 69) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 67
		Set_Eff_Text(id,"特效文字2","丐王真气");
    end

	--成昆
    if match_ID(pid, 18) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字2"] == nil then
			WAR.Person[id]["特效文字2"] = "混元霹雳功加力"
		else
			WAR.Person[id]["特效文字2"] = WAR.Person[id]["特效文字2"].."+混元霹雳功"
		end
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = "魔相·幻阴".."·"..WAR.Person[id]["特效文字3"]
		else
			WAR.Person[id]["特效文字3"] = "魔相·幻阴"
		end
    end

 	--殷天正
    if match_ID(pid, 12) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["特效动画"] = 67
		Set_Eff_Text(id,"特效文字2","鹰王真气");
    end

	--左冷禅
    if match_ID(pid, 22) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["特效动画"] = 1
		Set_Eff_Text(id,"特效文字2","寒冰真气");
    end

	--brolycjw: 黄药师
    if match_ID(pid, 57) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 95
		Set_Eff_Text(id,"特效文字2","奇门奥义");
    end

	--brolycjw: 谢烟客
    if match_ID(pid, 164) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["特效动画"] = 23
		Set_Eff_Text(id,"特效文字2","摩天居士");
    end

	--戚长发
    if match_ID(pid, 594) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 93
		Set_Eff_Text(id,"特效文字2","铁锁横江");
    end

	--慕容博
    if match_ID(pid, 113) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 93
		Set_Eff_Text(id,"特效文字2","参合真气");
    end

    --任我行 
    if match_ID(pid, 26) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 6
		Set_Eff_Text(id,"特效文字2","魔帝·吸星");
    end

	--何铁手
    if match_ID(pid, 83) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["特效动画"] =  92
		Set_Eff_Text(id,"特效文字2","红袖拂风");
    end

	--阿紫曼珠沙华，每杀一个人+200气攻
	if match_ID(pid, 47) then
		ng = ng + 200*WAR.MZSH
	end

    --枯荣
    if match_ID(pid, 102) and (inteam(pid)==false or JLSD(20,70+JY.Base["天书数量"]+math.modf(JY.Person[pid]["实战"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["特效动画"] = 23
		if math.random(2) == 1 then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = "有常无常·双树枯荣·"..WAR.Person[id]["特效文字3"]
			else
				WAR.Person[id]["特效文字3"] = "有常无常·双树枯荣"
			end
		else
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = "南北西东·非假非空·"..WAR.Person[id]["特效文字3"]
			else
				WAR.Person[id]["特效文字3"] = "南北西东·非假非空"
			end
		end
    end

    --天罡内功到极无误伤，50%几率发动天罡真气·
    if pid == 0 and JY.Base["标准"] == 6 and kfkind == 6 and level == 11 then
		WAR.WS = 1
		if JLSD(25, 75, pid) then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."+天罡真气·"..JY.Wugong[wugong]["名称"]
			else
				WAR.Person[id]["特效文字3"] = "天罡真气·"..JY.Wugong[wugong]["名称"]
			end
			ng = ng + JY.Wugong[wugong]["攻击力10"]
		end
    end

	--斗转幻梦星辰特效动画
	--WAR.Person[id]["特效动画"] = 107

    --使用降龙十八掌
    if wugong == 26 then
		--乔峰必出极意，洪七公，郭靖，拳主角40%
		if match_ID(pid, 50) or ((match_ID(pid, 69) or match_ID(pid, 55) or (pid == 0 and JY.Base["标准"] == 1)) and JLSD(30, 70, pid)) then
			Set_Eff_Text(id, "特效文字3", XL18JY[math.random(8)])
			ng = ng + 2300
			WAR.WS = 1
			for i = 1, (level) / 2 + 1 do
				for j = 1, (level) / 2 + 1 do
					SetWarMap(x + i - 1, y + j - 1, 4, 1)
					SetWarMap(x - i + 1, y + j - 1, 4, 1)
					SetWarMap(x + i - 1, y - j + 1, 4, 1)
					SetWarMap(x - i + 1, y - j + 1, 4, 1)
				end
			end
		--降龙招式
		elseif myrandom(15 + (level), pid) then
			Set_Eff_Text(id, "特效文字3", XL18[math.random(6)])
			ng = ng + 1500
			for i = 1, (1 + (level)) / 2 do
				for j = 1, (1 + (level)) / 2 do
					SetWarMap(WAR.Person[WAR.CurID]["坐标X"] + i * 2 - 1, WAR.Person[WAR.CurID]["坐标Y"] + j * 2 - 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["坐标X"] - i * 2 + 1, WAR.Person[WAR.CurID]["坐标Y"] + j * 2 - 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["坐标X"] + i * 2 - 1, WAR.Person[WAR.CurID]["坐标Y"] - j * 2 + 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["坐标X"] - i * 2 + 1, WAR.Person[WAR.CurID]["坐标Y"] - j * 2 + 1, 4, 1)
				end
			end
		end
    end

	--玄冥极意，主角有40%几率触发，暴怒必出，玄冥二老必出
	if wugong == 21 and level == 11 and pid == 0 and (match_ID(pid,647) or match_ID(pid,648) or WAR.LQZ[pid] == 100 or JLSD(30, 70, pid)) then
		Set_Eff_Text(id, "特效文字1", "玄冥极意")
		ng = ng + 1500
		WAR.WS = 1
		for i = 1, 5 do
			for j = 1, 5 do
				SetWarMap(x + i - 1, y + j - 1, 4, 1)
				SetWarMap(x - i + 1, y + j - 1, 4, 1)
				SetWarMap(x + i - 1, y - j + 1, 4, 1)
				SetWarMap(x - i + 1, y - j + 1, 4, 1)
			end
		end
	end

	--黯然极意
	if WAR.ARJY == 1 then
		ng = ng + 1200
		WAR.WS = 1
		for i = 1, 5 do
			for j = 1, 5 do
				SetWarMap(x + i - 1, y + j - 1, 4, 1)
				SetWarMap(x - i + 1, y + j - 1, 4, 1)
				SetWarMap(x + i - 1, y - j + 1, 4, 1)
				SetWarMap(x - i + 1, y - j + 1, 4, 1)
			end
		end
	end

	--六脉神剑，50%几率剑气碧烟横
	if wugong == 49 and JLSD(20,70,pid) then
		WAR.JQBYH = 1
		Set_Eff_Text(id, "特效文字3", "剑气碧烟横")
	end

	--使用六脉神剑
    if wugong == 49 then
		local jl = 0
    	--学会一阳指
     	if PersonKF(pid, 17) then
			jl = jl + 30
		end
		if myrandom(level+jl, pid) or (match_ID(pid, 53) and myrandom(level+jl, pid)) then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·" ..LMSJ[math.random(6)]
			else
				WAR.Person[id]["特效文字3"] = LMSJ[math.random(6)]
			end
			ng = ng + 2000
			if match_ID(pid, 53) then
				WAR.LMSJwav = 1
				WAR.WS = 1
			end
		end
    end


    --罗汉拳，易筋经变身，般若掌，60%几率，敌方必出
    if wugong == 1 and PersonKF(pid, 108) then
    	if inteam(pid) == false or JLSD(20, 80, pid) then
     	 	WAR.LHQ_BNZ = 1
    	end
    end

    --大力金刚掌，易筋经变身，达摩掌，40%几率，敌方必出
    if wugong == 22 and PersonKF(pid, 108)  then
    	if inteam(pid) == false or JLSD(40, 80, pid) then
			WAR.JGZ_DMZ = 1
    	end
    end

	--五毒神掌，李莫愁用有70%几率变赤练神掌
    if wugong == 3 and match_ID(pid, 161) and JLSD(10, 80, pid) then
		WAR.WD_CLSZ = 1
    end

    --铜人阵，9个强力铜人，直接触发达摩掌
    if pid > 480 and pid < 490 then
		WAR.Person[id]["特效文字2"] = "易筋经加力"
		ng = ng + 1200
		WAR.JGZ_DMZ = 1
    end

    --石破天，太玄神功，追加气攻
    if match_ID(pid, 38) and wugong == 102 and level == 11 then
		WAR.Person[id]["特效文字3"] = XKXSJ[math.random(4)]
		ng = ng + 1500
    end

    --狄云，神经照，追加气攻
    if match_ID(pid, 37) and wugong == 94 and level == 11 then
		WAR.Person[id]["特效文字3"] = "神照经·无影神拳"
		ng = ng + 1000
    end

    --小昭，圣火，追加气攻
    if match_ID(pid, 66) and wugong == 93 and level == 11 then
		local zs = {"赤沙流虹降心火","恍起未明净萦魂","星引瀚光沙劫海","业火焚心无量尊"}
		WAR.Person[id]["特效文字3"] = zs[math.random(4)]
		ng = ng + 1200
    end

    --苗家剑法，为极，配合胡家刀法。 60%刀剑合壁
    if wugong == 44 and level == 11 and math.random(10) < 7 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["武功" .. i] == 67 and JY.Person[pid]["武功等级" .. i] == 999 then
				Set_Eff_Text(id, "特效文字1", "胡刀苗剑 归真合一")
				WAR.Person[id]["特效动画"] = 6
				WAR.DJGZ = 1
				ng = ng + 1500
				break
			end
		end
    end

    --胡家刀法，为极，配合苗家剑法。 60%刀剑合壁
    if wugong == 67 and level == 11 and math.random(10) < 7 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["武功" .. i] == 44 and JY.Person[pid]["武功等级" .. i] == 999 then
				Set_Eff_Text(id, "特效文字1", "胡刀苗剑 归真合一")
				WAR.Person[id]["特效动画"] = 6
				WAR.DJGZ = 1
				ng = ng + 1500
				break
			end
		end
    end

	--紫气天罗组合，气攻+1000
	if (wugong == 3 or wugong == 9 or wugong == 5 or wugong == 21 or wugong == 118) and ZiqiTL(pid) then
		ng = ng + 1000
		Set_Eff_Text(id, "特效文字1", "紫气天罗")
	end

	--无酒不欢：主运紫霞，50%几率剑系气攻+1000
	if Curr_NG(pid, 89) and kfkind == 3 and JLSD(20, 70, pid) then
		ng = ng + 1000
		Set_Eff_Text(id, "特效文字3", "紫霞剑气")
	end

	--破尽天下，增加1000点气攻
	if WAR.PJTX == 1 then
		ng = ng + 1000
	end

	--装备鸳鸯刀，5级开始，夫妻追加500气攻
	if JY.Person[pid]["武器"] == 217 and wugong == 62 and JY.Thing[217]["装备等级"] >=5 then
		ng = ng + 500
	end
	if JY.Person[pid]["武器"] == 218 and wugong == 62 and JY.Thing[218]["装备等级"] >=5 then
		ng = ng + 500
	end

	--五岳剑法组合，50%几率额外气攻+1000，暴怒必发动
	if wugong >= 30 and wugong <= 34 and WuyueJF(pid) and (WAR.LQZ[pid] == 100 or JLSD(20, 70, pid))then
		ng = ng + 1000
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = "气贯五岳·"..WAR.Person[id]["特效文字3"]
		else
			WAR.Person[id]["特效文字3"] = "气贯五岳"
		end
	end

	--琴棋书画：棋盘招式，额外杀气
	if wugong == 72 and QinqiSH(pid) then
		ng = ng + 1200
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·棋高一着"
		else
			WAR.Person[id]["特效文字3"] = "棋高一着"
		end
		--50%几率触发再次追加杀气
		if JLSD(20, 70, pid) then
			ng = ng + 1000
			if WAR.Person[id]["特效文字1"] ~= nil then
				WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·星罗棋布"
			else
				WAR.Person[id]["特效文字1"] = "星罗棋布"
			end
		end
    end

	--沧溟刀法，30%几率，额外杀气，必定流血
	--刀主二次判定
	if wugong == 153 and (JLSD(30, 60, pid) or (pid == 0 and JY.Base["标准"] == 4 and JLSD(30,60,pid))) then
		WAR.CMDF = 1
		ng = ng + 1000
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·颠动沧溟"
		else
			WAR.Person[id]["特效文字1"] = "颠动沧溟"
		end
	end

	--龙象加力，气攻+1000
	if WAR.NGJL == 103 then
		ng = ng + 1000
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+" .."龙象之力"
		else
			WAR.Person[id]["特效文字1"] = "龙象之力"
		end
	end

	--王重阳北斗七闪追加气攻1000点
	if match_ID(pid, 129) and WAR.CYZX[pid] ~= nil and WAR.BDQS > 0 then
		ng = ng + 1000
		local BDQS = {"天枢", "天璇", "天玑", "天权", "玉衡", "开阳", "摇光"}
		if WAR.Person[id]["特效文字2"] ~= nil then
			WAR.Person[id]["特效文字2"] = WAR.Person[id]["特效文字2"] .. "+" .."北斗七闪·"..BDQS[WAR.BDQS]
		else
			WAR.Person[id]["特效文字2"] = "北斗七闪·"..BDQS[WAR.BDQS]
		end
	end

	--七伤拳，机率造成内伤17点
	--谢逊必出
	if wugong == 23 and (match_ID(pid, 13) or WAR.LQZ[pid] == 100 or JLSD(30, 60, pid))then
		WAR.YZQS = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+一震七伤"
		else
			WAR.Person[id]["特效文字1"] = "一震七伤"
		end
	end

    --钟灵 使用闪电貂，可偷窃，朱聪妙手空空也可
    if (match_ID(pid, 90) and wugong == 113) or (match_ID(pid, 131) and wugong == 116) then
		WAR.TD = -2
		--蓝烟清：挑战战斗不可偷东西
		if WAR.ZDDH == 226 or WAR.ZDDH == 79 then
			WAR.TD = -1;
		end
    end

	--宋远桥使用太极拳或太极剑攻击后自动进入防御状态
	if match_ID(pid, 171) and (wugong == 16 or wugong == 46) then
		WAR.WDRX = 1
	end

    --黄药师，第一次攻击，伤内力500，内力不足500追加伤害
    if match_ID(pid, 57) and WAR.ACT == 1 then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				if JY.Person[WAR.Person[j]["人物编号"]]["内力"] > 500 then
					JY.Person[WAR.Person[j]["人物编号"]]["内力"] = JY.Person[WAR.Person[j]["人物编号"]]["内力"] - 500
					WAR.Person[j]["内力点数"] = (WAR.Person[j]["内力点数"] or 0) - 500;
				else
					WAR.Person[j]["内力点数"] = (WAR.Person[j]["内力点数"] or 0) - JY.Person[WAR.Person[j]["人物编号"]]["内力"];
					JY.Person[WAR.Person[j]["人物编号"]]["内力"] = 0
					--无酒不欢：记录人物血量
					WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"]
					JY.Person[WAR.Person[j]["人物编号"]]["生命"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"] - 100*JY.Person[WAR.Person[j]["人物编号"]]["血量翻倍"]
					WAR.Person[j]["生命点数"] = (WAR.Person[j]["生命点数"] or 0) - 100*JY.Person[WAR.Person[j]["人物编号"]]["血量翻倍"];
				end
				WAR.TXXS[WAR.Person[j]["人物编号"]] = 1
			end
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+" .."魔音·碧海潮生曲"
		else
			WAR.Person[id]["特效文字1"] = "魔音·碧海潮生曲"
		end
		WAR.Person[id]["特效动画"] = 39
    end

	--何铁手五毒随机2-5倍威力
	if match_ID(pid, 83) and wugong == 3 then
		WAR.HTS = math.random(2, 5)
    end

    --喵姐 无误伤
    if match_ID(pid, 92) then
		WAR.WS = 1
    end

    --欧阳锋 无误伤
    if match_ID(pid, 60) then
		WAR.WS = 1
    end

    --东方不败 无误伤
    if match_ID(pid, 27) then
		WAR.WS = 1
    end

	--扫地 无误伤
    if match_ID(pid, 114) then
		WAR.WS = 1
    end

	--阿青，越女无误伤
	if match_ID(pid, 604) and wugong == 156 then
		WAR.WS = 1
	end

	--剑仙剑魔战，独孤无误伤
	if match_ID(pid, 592) and WAR.ZDDH == 291 then
		WAR.WS = 1
	end

    --乔峰，郭靖，洪七公，使用降龙十八掌 无误伤
    if (match_ID(pid, 50) or match_ID(pid, 55) or match_ID(pid, 69)) and wugong == 26 then
		WAR.WS = 1
    end

    --萧中慧使用夫妻刀法 无误伤
    if match_ID(pid, 77) and wugong == 62 then
		WAR.WS = 1
    end

    --令狐冲 二觉之后，使用独孤九剑 无误伤
    if match_ID_awakened(pid, 35, 2) and wugong == 47 then
		WAR.WS = 1
    end

	--玉女素心剑 无误伤
	if wugong == 139 then
		WAR.WS = 1
	end

    --金轮法王 气攻+2500
    if match_ID(pid, 62) then
		ng = ng + 2500
    end

    --霍都 气攻+1000
    if match_ID(pid, 84) then
		ng = ng + 1000
    end

    --花铁干，使用中平枪法，气攻+1500
    if match_ID(pid, 52) and wugong == 70 then
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+" .."中平神枪"
		else
			WAR.Person[id]["特效文字3"] = "中平神枪"
		end
		ng = ng + 1500
    end

    --霍青桐，使用三分剑法，伤体力
    if match_ID(pid, 74) and wugong == 29 then
		WAR.HQT = 1
    end

    --程英，使用玉箫剑法，杀内力300
    if match_ID(pid, 63) and wugong == 38 then
		WAR.CY = 1
    end

    --杨过 攻击，非吼 全体集气减100
    if match_ID(pid, 58) and WAR.XK ~= 2 then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - 100
			end
		end
		if WAR.Person[id]["特效动画"] == nil then
			WAR.Person[id]["特效动画"] = 89
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+" .."西狂之怒啸"
		else
			WAR.Person[id]["特效文字1"] = "西狂之怒啸"
		end
    end

    --杨过吼
    if WAR.XK == 2 and match_ID(pid, 58) and WAR.Person[WAR.CurID]["我方"] == WAR.XK2 then
		for e = 0, WAR.PersonNum - 1 do
			if WAR.Person[e]["死亡"] == false and WAR.Person[e]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				WAR.Person[e].TimeAdd = WAR.Person[e].TimeAdd - math.modf(JY.Person[WAR.Person[WAR.CurID]["人物编号"]]["内力"] / 5)
				if WAR.Person[e].Time < -450 then
					WAR.Person[e].Time = -450
				end
				JY.Person[WAR.Person[e]["人物编号"]]["内力"] = JY.Person[WAR.Person[e]["人物编号"]]["内力"] - math.modf(JY.Person[WAR.Person[WAR.CurID]["人物编号"]]["内力"] / 5)
				if JY.Person[WAR.Person[e]["人物编号"]]["内力"] < 0 then
					JY.Person[WAR.Person[e]["人物编号"]]["内力"] = 0
				end
				JY.Person[WAR.Person[e]["人物编号"]]["生命"] = JY.Person[WAR.Person[e]["人物编号"]]["生命"] - math.modf(JY.Person[WAR.Person[WAR.CurID]["人物编号"]]["内力"] / 25)
			end
			if JY.Person[WAR.Person[e]["人物编号"]]["生命"] < 0 then
				JY.Person[WAR.Person[e]["人物编号"]]["生命"] = 0
			end
		end

		--吼过之后，内力为0，内力最大值-1000，并且用声望控制上限
		if inteam(pid) then
			JY.Person[pid]["内力"] = 0
			JY.Person[pid]["内力最大值"] = JY.Person[pid]["内力最大值"] - 1000
			JY.Person[300]["声望"] = JY.Person[300]["声望"] + 1
		else
			AddPersonAttrib(pid, "内力", -1000)  --做敌方内力只减1000
		end

		if JY.Person[pid]["内力最大值"] < 500 then
			JY.Person[pid]["内力最大值"] = 500
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+" .."西狂之震怒·雷霆狂啸"
		else
			WAR.Person[id]["特效文字1"] = "西狂之震怒·雷霆狂啸"
		end
		WAR.Person[id]["特效动画"] = 6
		WAR.XK = 3
	end

    --任盈盈，使用持瑶琴，60%几率无形剑气
    if match_ID(pid, 73) and wugong == 73 and math.random(10) < 7 then
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+" .."七弦无形剑气"
		else
			WAR.Person[id]["特效文字3"] = "七弦无形剑气"
		end
		WAR.Person[id]["特效动画"] = 89
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				WAR.TXXS[WAR.Person[j]["人物编号"]] = 1
				--无酒不欢：记录人物血量
				WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"]
				JY.Person[WAR.Person[j]["人物编号"]]["生命"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"] - 50*JY.Person[WAR.Person[j]["人物编号"]]["血量翻倍"]
				WAR.Person[j]["生命点数"] = (WAR.Person[j]["生命点数"] or 0) - 50*JY.Person[WAR.Person[j]["人物编号"]]["血量翻倍"]
				--沉睡状态的敌人会醒来
				if WAR.CSZT[WAR.Person[j]["人物编号"]] ~= nil then
					WAR.CSZT[WAR.Person[j]["人物编号"]] = nil
				end
			end
		end
	end

	--剑胆琴心 持瑶琴回血5%，减少10内伤
	if wugong == 73 and JiandanQX(pid) then
		Set_Eff_Text(id, "特效文字3", "清心普善咒")
		WAR.Person[id]["特效动画"] = 89
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", JY.Person[pid]["生命"]*0.05)
		WAR.Person[WAR.CurID]["内伤点数"] = (WAR.Person[WAR.CurID]["内伤点数"] or 0) + AddPersonAttrib(pid, "受伤程度", -10)
	end

	--七夕任盈盈加强版效果
    if match_ID(pid, 611) and wugong == 73 then
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+" .."魔音搜魂"
		else
			WAR.Person[id]["特效文字3"] = "魔音搜魂"
		end
		WAR.Person[id]["特效动画"] = 89
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				JY.Person[WAR.Person[j]["人物编号"]]["生命"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"] - 100*JY.Person[WAR.Person[j]["人物编号"]]["血量翻倍"]
			end
		end
	end

    --张三丰 万法自然，集气从500开始
    if match_ID(pid, 5) and math.random(10) < 8 then
		WAR.ZSF = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+" .."万法自然"
		else
			WAR.Person[id]["特效文字1"] ="万法自然"
		end
    end

    --虚竹  福泽加护，集气从200开始
    if match_ID(pid, 49) and math.random(10) < 7 then
		WAR.XZZ = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .."+".."福泽加护"
		else
			WAR.Person[id]["特效文字1"] = "福泽加护"
		end
    end

	--封不平狂风快剑，使用剑法回气
    if match_ID(pid, 142) and kfkind == 3 then
		WAR.KFKJ = 1
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .."+".."狂风快剑"
		else
			WAR.Person[id]["特效文字3"] = "狂风快剑"
		end
    end

	--九剑真传，荡剑式，攻击后回气+200
	if WAR.JJZC == 4 and pid == 0 then
		WAR.JJDJ = 1
	end

    --东方不败  葵花点穴手，气攻+1000
	--葵尊必出点穴手
    if (match_ID(pid, 27) and math.random(10) < 7) or (WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and pid == 27) then
		ng = ng + 1000
		WAR.BFX = 1
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+" .."葵花点穴手"
		else
			WAR.Person[id]["特效文字3"] = "葵花点穴手"
		end
    end

    --程灵素 攻击全屏中毒+20
	--扣除当前血量7%
    if match_ID(pid, 2) then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				local loss = math.modf(JY.Person[WAR.Person[j]["人物编号"]]["生命"]*0.07)
				--无酒不欢：记录人物血量
				WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"]
				JY.Person[WAR.Person[j]["人物编号"]]["生命"] = JY.Person[WAR.Person[j]["人物编号"]]["生命"] - loss
				WAR.Person[j]["生命点数"] = (WAR.Person[j]["生命点数"] or 0) - loss
				WAR.Person[j]["中毒点数"] = (WAR.Person[j]["中毒点数"] or 0) + AddPersonAttrib(WAR.Person[j]["人物编号"], "中毒程度", 20)
				WAR.TXXS[WAR.Person[j]["人物编号"]] = 1
				--沉睡状态的敌人会醒来
				if WAR.CSZT[WAR.Person[j]["人物编号"]] ~= nil then
					WAR.CSZT[WAR.Person[j]["人物编号"]] = nil
				end
			end
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .."+".."七心海棠"
		else
			WAR.Person[id]["特效文字1"] = "七心海棠"
		end
		WAR.Person[id]["特效动画"] = 64
    end

    --鸠摩智  使用火焰刀法，加内伤30，加杀集气1000
    --普通角色使用有30%的机率
	--刀主二次判定
    if wugong == 66 and level == 11 and (match_ID(pid, 103) or JLSD(30,60,pid) or (pid == 0 and JY.Base["标准"] == 4 and JLSD(30,60,pid)))  then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
				WAR.Person[j]["内伤点数"] = (WAR.Person[j]["内伤点数"] or 0) + AddPersonAttrib(WAR.Person[j]["人物编号"], "受伤程度", 30)
				WAR.TXXS[WAR.Person[j]["人物编号"]] = 1
			end
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .."+".."大轮密宗·火焰刀"
		else
			WAR.Person[id]["特效文字1"] = "大轮密宗·火焰刀"
		end
		WAR.Person[id]["特效动画"] = 58
		ng = ng + 1000
    end

	--罗汉伏魔加力文字特效
	--同时学有易筋神功+罗汉伏魔功，主运易筋神功必出“罗汉伏魔”特效
	if WAR.NGJL == 96 or (Curr_NG(pid, 108) and PersonKF(pid, 96)) then
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+罗汉伏魔";
		else
			WAR.Person[id]["特效文字1"] = "罗汉伏魔"
		end
	end

    --太极拳，借力打力
    if wugong == 16 then
		if WAR.tmp[3000 + pid] == nil then
			WAR.tmp[3000 + pid] = 0
		elseif 0 < WAR.tmp[3000 + pid] then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."·借力打力"
			else
				WAR.Person[id]["特效文字3"] = "借力打力"
			end
			ng = ng + WAR.tmp[3000 + pid]
		end
    end

	--天山折梅手，杀气提高
	if wugong == 14 then
		local exng = 0
		local CN_num = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一","十二"}
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["武功"..i] ~= 14 and JY.Person[pid]["武功等级"..i] == 999 then
				ng = ng + 100
				exng = exng + 1
			end
		end
		if exng > 0 then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."+天山折梅"..CN_num[exng]
			else
				WAR.Person[id]["特效文字3"] = "天山折梅"..CN_num[exng]
			end
		end
	end

    --虚竹使用天山六阳掌或折梅手，出生死符，杀集气+1700
    if (wugong == 8 or wugong == 14) and match_ID(pid, 49) and PersonKF(pid, 101) and (JLSD(20, 80, pid) or WAR.NGJL == 98) then
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."+灵鹫宫绝学·生死符"
		else
			WAR.Person[id]["特效文字3"] = "灵鹫宫绝学·生死符"
		end
		ng = ng + 1700
		WAR.TZ_XZ = 1
    end

    --蓝烟清：李文秀使用特系攻击60%的机率大幅度杀集气
    if match_ID(pid, 590) and kfkind == 5 and JLSD(20, 80, pid) then
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."+".."心秀天铃·星月争辉"
		else
			WAR.Person[id]["特效文字3"] = "心秀天铃·星月争辉"
		end
    	ng = ng + 1200
    end

	--王语嫣御法绝尘
	local YufaJC = 0
	for i = 0, WAR.PersonNum - 1 do
		local yfid = WAR.Person[i]["人物编号"]
		if WAR.Person[i]["死亡"] == false and WAR.Person[i]["我方"] and match_ID(yfid, 76) and Xishu_sum(yfid) >= 500 and inteam(pid) == false then
			YufaJC = 1
			break
		end
	end

	--武功招式加杀集气
	if YufaJC == 0 then
		--风清扬，暴怒九剑触发无招胜有招
		if match_ID(pid, 140) and wugong == 47 and WAR.LQZ[pid] == 100 then
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."·".."无招胜有招"
			else
				WAR.Person[id]["特效文字3"] = "无招胜有招"
			end
			ng = ng + 2000
			WAR.FQY = 1
		--看有没有招式
		elseif CC.KFMove[wugong] ~= nil then
			--npc必出招，小无相功加力必出招式，暴怒必出招式，辟邪必出招
			if inteam(pid) == false or myrandom(level, pid) or WAR.NGJL == 98 or WAR.LQZ[pid] == 100 or (wugong == 48 and level == 11 and WAR.DZXY == 0) then
				local num
				if wugong == 48 and inteam(pid) and WAR.DZXY ~= 1 and WAR.AutoFight == 0 then	--辟邪招式固定
					num = WAR.BXZS
				else
					num = math.random(#CC.KFMove[wugong])										--从数组从随机抽取一个
				end
				if WAR.Person[id]["特效文字3"] ~= nil then
					WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"].."·"..CC.KFMove[wugong][num][1]
				else
					WAR.Person[id]["特效文字3"] = CC.KFMove[wugong][num][1]
				end
				ng = ng + CC.KFMove[wugong][num][2]
			end
		end
	end

	--张三丰，40%机率增加1000气攻
    if match_ID(pid, 5) and WAR.Person[id]["特效文字3"] ~= nil and JLSD(30, 70, pid) then
		WAR.Person[id]["特效文字3"] = "化朽为奇" .. "·" .. WAR.Person[id]["特效文字3"]
		ng = ng + 1000
    end

	--王重阳，全真剑法，60%几率重阳剑气777气攻
	if wugong == 39 and match_ID(pid, 129) and JLSD(20, 80, pid) then
		ng = ng + 777
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = "重阳剑气·"..WAR.Person[id]["特效文字3"]
		else
			WAR.Person[id]["特效文字3"] = "重阳剑气"
		end
	end

	--弹指神通，配合桃花绝技，气攻+1000
	if wugong == 18 and TaohuaJJ(pid) then
		ng = ng + 1000
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·无影神石"
		else
			WAR.Person[id]["特效文字3"] = "无影神石"
		end
	end

	--谢无悠，九种文字
    if match_ID(pid, 596) then
		local WZTS = {"一念无量","现世执妄","悟入幻想","草木成佛","天人五衰","六根清净","众生无情","生死有命","半身大悟"}
		local JTYL = math.random(9)
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+九天一流·"..WZTS[JTYL]
		else
			WAR.Person[id]["特效文字3"] =  "九天一流·"..WZTS[JTYL]
		end
    end

    --打狗棒法 极意
    if wugong == 80 and level == 11 and (WAR.LQZ[pid] == 100 or JLSD(30, 70, pid) or (pid == 0 and JY.Base["标准"] == 5 and JLSD(30, 75, pid))) then
		WAR.Person[id]["特效文字3"] = "打狗棒法绝学--天下无狗"
		WAR.Person[id]["特效动画"] = 89
		if ng < 2400 then
			ng = 2400
		end
		WAR.WS = 1
		for i = 1, 6 do
			for j = 1, 6 do
			  SetWarMap(x + i - 1, y + j - 1, 4, 1)
			  SetWarMap(x - i + 1, y + j - 1, 4, 1)
			  SetWarMap(x + i - 1, y - j + 1, 4, 1)
			  SetWarMap(x - i + 1, y - j + 1, 4, 1)
			end
		end
    end

    --蓝烟清：胡家刀法，极意
    --刀系主角40%，胡斐50%，暴怒必出
    if wugong == 67 and level == 11 and ((pid == 0 and JY.Base["标准"] == 4 and (WAR.LQZ[pid] == 100 or JLSD(30,70,pid))) or (match_ID(pid, 1) and (WAR.LQZ[pid] == 100 or JLSD(20,70,pid)))) then
		local HDJY = {"极意·伏虎式","极意·拜佛听经","极意·穿手藏刀","极意·沙鸥掠波","极意·参拜北斗","极意·闭门铁扇刀","极意·缠身摘心刀","极意·进步连环刀","极意·八方藏刀式"};
		WAR.Person[id]["特效文字3"] = HDJY[math.random(9)];
		WAR.Person[id]["特效动画"] = 6
		ng = ng + 1500
		WAR.WS = 1
		for i = 1, 5 do
			for j = 1, 5 do
				SetWarMap(x + i - 1, y + j - 1, 4, 1)
				SetWarMap(x - i + 1, y + j - 1, 4, 1)
				SetWarMap(x + i - 1, y - j + 1, 4, 1)
				SetWarMap(x - i + 1, y - j + 1, 4, 1)
			end
		end
    end

    --杨过，神雕，标主剑神 玄铁极意
	--无招式时必触发，暴怒时必出
    if wugong == 45 and level == 11 and (match_ID(pid, 58) or match_ID(pid, 628) or (pid == 0 and JY.Base["标准"] == 3)) and (WAR.LQZ[pid] == 100 or WAR.Person[id]["特效文字3"] == nil) then
		WAR.Person[id]["特效文字3"] = "重剑真传·浪如山涌剑如虹"
		WAR.Person[id]["特效动画"] = 84
		ng = ng + 1800
		WAR.WS = 1
		for i = 1, 5 do
			for j = 1, 5 do
				SetWarMap(x + i - 1, y + j - 1, 4, 1)
				SetWarMap(x - i + 1, y + j - 1, 4, 1)
				SetWarMap(x + i - 1, y - j + 1, 4, 1)
				SetWarMap(x - i + 1, y - j + 1, 4, 1)
			end
		end
    end

    --霍都攻击，中毒+13~16
    if match_ID(pid, 84) and math.random(10) < 7 then
		WAR.HDWZ = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"].."+".."暗箭·扇中钉"
		else
			WAR.Person[id]["特效文字1"] = "暗箭·扇中钉"
		end
		WAR.Person[id]["特效动画"] = 89
    end

    --葵花神功 刺目
    if wugong == 48 and PersonKF(pid, 105) then
		WAR.KHBX = 2
		WAR.Person[id]["特效文字1"] = "真辟邪剑法·葵花刺目";
		WAR.Person[id]["特效动画"] = 6
    end

	--葵花尊者必刺目
	if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and pid == 27 then
		WAR.KHBX = 2
		WAR.Person[id]["特效文字1"] = "葵花诀·葵花刺目";
		WAR.Person[id]["特效动画"] = 6
	end

    --盲目状态，20%几率攻击无效
    if WAR.KHCM[pid] == 2 and math.random(10) <= 2 then
		WAR.MMGJ = 1
		WAR.Person[id]["特效动画"] = 89
		WAR.Person[id]["特效文字2"] = "盲目状态·攻击无效"
    end

	--袁承志觉醒后，生命低于30%，50%几率出金蛇奥义
	if match_ID_awakened(pid, 54, 1) and wugong == 40 and JY.Person[pid]["生命"] <= (JY.Person[pid]["生命最大值"]*0.3) and JLSD(20,70,pid) then
		WAR.JSAY = 1
		ng = ng + 2000
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[i]["死亡"] == false then
				local offset1 = math.abs(WAR.Person[WAR.CurID]["坐标X"] - WAR.Person[i]["坐标X"])
				local offset2 = math.abs(WAR.Person[WAR.CurID]["坐标Y"] - WAR.Person[i]["坐标Y"])
				if offset1 <= 8 and offset2 <= 8 then
					SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 4, 1)
				end
			end
		end
	end

    local pz = math.modf(JY.Person[0]["资质"] / 10)

    --主角剑神大招，全屏攻击
    if pid == 0 and JY.Base["标准"] == 3 and 120 <= TrueYJ(pid) and 0 < JY.Person[pid]["武功9"] and kfkind == 3 and wugong ~= 43 and JLSD(25, 60 + pz, pid) and JY.Person[pid]["六如觉醒"] > 0 then
		CleanWarMap(4, 0)
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[i]["死亡"] == false then
				SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 4, 1)
			end
		end
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[3]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[3] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1500
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[3] .. TFSSJ[3], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
				Cls()
				NewDrawString(-1, -1, ZJTF[3] .. TFSSJ[3], C_GOLD, CC.DefaultFont + i*2)
				ShowScreen()
				lib.Delay(500)
			else
				lib.Delay(1)
			end
		end
		WAR.JSYX = 1
    end

    --主角拳系大招
    if pid == 0 and JY.Base["标准"] == 1 and 0 < JY.Person[pid]["武功9"] and 120 <= TrueQZ(pid) and JLSD(25, 60 + pz, pid) and kfkind == 1 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[1]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[1] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1200
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[1] .. TFSSJ[1], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
			  Cls()
			  NewDrawString(-1, -1, ZJTF[1] .. TFSSJ[1], C_GOLD, CC.DefaultFont + i*2)
			  ShowScreen()
			  lib.Delay(500)
			else
			  lib.Delay(1)
			end
		end
		WAR.LXZQ = 1
    end

    --主角指法大招
    if pid == 0 and JY.Base["标准"] == 2 and 0 < JY.Person[pid]["武功9"] and 120 <= TrueZF(pid) and JLSD(25, 60 + pz, pid) and kfkind == 2 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[2]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[2] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1100
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[2] .. TFSSJ[2], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
			  Cls()
			  NewDrawString(-1, -1, ZJTF[2] .. TFSSJ[2], C_GOLD, CC.DefaultFont + i*2)
			  ShowScreen()
			  lib.Delay(500)
			else
			  lib.Delay(1)
			end
		end
		WAR.LXYZ = 1
    end

    --主角特系大招
    if pid == 0 and JY.Base["标准"] == 5 and 0 < JY.Person[pid]["武功9"] and 120 <= JY.Person[pid]["特殊兵器"] and JLSD(25, 65 + pz, pid) and kfkind == 5 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[5]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[5] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1000
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[5] .. TFSSJ[5], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
			  Cls()
			  NewDrawString(-1, -1, ZJTF[5] .. TFSSJ[5], C_GOLD, CC.DefaultFont + i*2)
			  ShowScreen()
			  lib.Delay(500)
			else
			  lib.Delay(1)
			end
		end
		WAR.GCTJ = 1
    end

    --主角刀系大招
    if pid == 0 and JY.Base["标准"] == 4 and 0 < JY.Person[pid]["武功9"] and 120 <= JY.Person[pid]["耍刀技巧"] and JLSD(25, 65 + pz, pid) and kfkind == 4 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[4]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[4] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1500
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[4] .. TFSSJ[4], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
			  Cls()
			  NewDrawString(-1, -1, ZJTF[4] .. TFSSJ[4], C_GOLD, CC.DefaultFont + i*2)
			  ShowScreen()
			  lib.Delay(500)
			else
			  lib.Delay(1)
			end
		end
		WAR.ASKD = 1
		--触发后给自己加怒气25
		WAR.YZHYZ = WAR.YZHYZ + 25
    end

    --主角天罡大招，内功可触发
    if pid == 0 and JY.Base["标准"] == 6 and 0 < JY.Person[pid]["武功9"] and JLSD(25, 60 + pz, pid) and kfkind == 6 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[6]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[6] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		ng = ng + 1300
		WAR.WS = 1
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[6] .. TFSSJ[6], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
				Cls()
				NewDrawString(-1, -1, ZJTF[6] .. TFSSJ[6], C_GOLD, CC.DefaultFont + i*2)
				ShowScreen()
				lib.Delay(500)
			else
				lib.Delay(1)
			end
		end
		WAR.JSTG = 1
	end

    --主角毒王大招，自身中毒100可触发
    if pid == 0 and JY.Base["标准"] == 9 and 0 < JY.Person[pid]["武功9"] and JLSD(25, 60 + pz, pid) and JY.Person[pid]["中毒程度"] == 100 and JY.Person[pid]["六如觉醒"] > 0 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] == nil then
			WAR.Person[id]["特效文字3"] = ZJTF[9]
		else
			WAR.Person[id]["特效文字3"] = ZJTF[9] .. "·" .. WAR.Person[id]["特效文字3"]
		end
		WAR.WS = 1
		JY.Person[pid]["中毒程度"] = 0
		Cls()

		ShowScreen()
		lib.Delay(40)
		for i = 1, 10 do
			NewDrawString(-1, -1, ZJTF[9] .. TFSSJ[9], C_GOLD, CC.DefaultFont + i*2)
			ShowScreen()
			if i == 10 then
				Cls()
				NewDrawString(-1, -1, ZJTF[9] .. TFSSJ[9], C_GOLD, CC.DefaultFont + i*2)
				ShowScreen()
				lib.Delay(500)
			else
				lib.Delay(1)
			end
		end
		WAR.YTML = 1
	end

	--欧阳克，暴怒使用雪山白驼掌，变为灵蛇拳
	if match_ID(pid,61) and wugong == 9 and WAR.LQZ[pid] == 100 then
		WAR.OYK = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·灵蛇拳"
		else
			WAR.Person[id]["特效文字1"] = "灵蛇拳"
		end
	end

	--郭靖，降龙连击时随机后劲，有余不尽
	if match_ID(pid, 55) and wugong == 26 and WAR.ACT > 1 then
		local txwz = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一","十二","十三"}
		if inteam(pid) then
			WAR.YYBJ = math.random(0, JY.Base["天书数量"])
			if WAR.YYBJ > 13 then
				WAR.YYBJ = 13
			end
			--保底天书数量-7
			if JY.Base["天书数量"] > 7 then
				if WAR.YYBJ < JY.Base["天书数量"] - 7 then
					WAR.YYBJ = JY.Base["天书数量"] - 7
				end
			end
		else
			WAR.YYBJ = math.random(1, 10)
		end
		if WAR.YYBJ > 0 then
			ng = ng + WAR.YYBJ*150
			if WAR.Person[id]["特效文字1"] ~= nil then
				WAR.Person[id]["特效文字1"] = "降龙·有余不尽·"..txwz[WAR.YYBJ].."重后劲".."+"..WAR.Person[id]["特效文字1"]
			else
				WAR.Person[id]["特效文字1"] = "降龙·有余不尽·"..txwz[WAR.YYBJ].."重后劲"
			end
		end
	end

	--阿青，天元剑气
	if match_ID(pid, 604) and kfkind == 3 then
		WAR.TYJQ = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·天元剑气"
		else
			WAR.Person[id]["特效文字1"] = "天元剑气"
		end
    end

	--林朝英，流风回雪
	if match_ID(pid, 605) and JLSD(20, 80, pid) then
		WAR.LFHX = 1
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·流风回雪"
		else
			WAR.Person[id]["特效文字3"] = "流风回雪"
		end
    end

	--七夕黄蓉，打狗缠字诀
	if wugong == 80 and match_ID(pid, 613) then
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+打狗棒法·缠字诀"
		else
			WAR.Person[id]["特效文字1"] = "打狗棒法·缠字诀"
		end
	end

	--进阶泰山，使用后20时序内闪避
	if wugong == 31 and PersonKF(pid,175) then
		WAR.TSSB[pid] = 20
	end

	--主运天罗地网，减少敌方移动
	if Curr_QG(pid,148) then
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+柔网势"
		else
			WAR.Person[id]["特效文字1"] = "柔网势"
		end
	end

	--无酒不欢：举火燎原，金乌+燃木+火焰刀，暴怒造成引燃效果
	if (wugong == 61 or wugong == 65 or wugong == 66) and JuHuoLY(pid) and WAR.LQZ[pid] == 100 then
		Set_Eff_Text(id,"特效文字2","举火燎原")
	end

	--无酒不欢：利刃寒锋，修罗+阴风+沧溟，暴怒造成冻结效果
	if (wugong == 58 or wugong == 174 or wugong == 153) and LiRenHF(pid) and WAR.LQZ[pid] == 100 then
		Set_Eff_Text(id,"特效文字2","利刃寒锋")
	end

	--主运太玄，太玄之重，不加怒
	if Curr_NG(pid, 102) and JLSD(20, 70 + JY.Base["天书数量"] + math.modf(JY.Person[pid]["实战"]/50), pid) then
		WAR.TXZZ = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·太玄之重"
		else
			WAR.Person[id]["特效文字1"] = "太玄之重"
		end
    end

	--一灯用一阳指，无明业火
	if match_ID(pid, 65) and wugong == 17 then
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = "无明业火·"..WAR.Person[id]["特效文字1"]
		else
			WAR.Person[id]["特效文字1"] = "无明业火"
		end
	end

	--周伯通空明之武道使敌方不会护体，初始几率25%，每20点实战+1%几率
	if match_ID(pid, 64) and JLSD(20, 45 + math.modf(JY.Person[pid]["实战"]/20), pid) then
		WAR.KMZWD = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = "空明之武道·"..WAR.Person[id]["特效文字1"]
		else
			WAR.Person[id]["特效文字1"] = "空明之武道"
		end
    end

	--九剑真传，剑法主动攻击70%几率触发4种特效之一
	--七夕令狐冲自带
	if ((pid == 0 and JY.Person[592]["论剑奖励"] == 1 and JLSD(15, 85,pid))
		or match_ID(pid, 610))
		and kfkind == 3 then
		local t = math.random(4)
		local wz = {"离剑式","倒剑式","撩剑式","荡剑式"}
		WAR.JJZC = t
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .."+九剑真传·"..wz[t]
		else
			WAR.Person[id]["特效文字1"] = "九剑真传·"..wz[t]
		end
	end

	--琴棋书画：持瑶琴，不加怒
	if wugong == 73 and QinqiSH(pid) then
		WAR.QQSH1 = 1
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·琴音悦耳"
		else
			WAR.Person[id]["特效文字1"] = "琴音悦耳"
		end
		--50%几率触发清怒
		if JLSD(20, 70, pid) then
			WAR.QQSH1 = 2
			if WAR.Person[id]["特效文字1"] ~= nil then
				WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "·菩提清心"
			else
				WAR.Person[id]["特效文字1"] = "菩提清心"
			end
		end
    end

	--琴棋书画：妙笔丹青，冰封
	if wugong == 142 and QinqiSH(pid) then
		--60%几率冰封
		if JLSD(20, 80, pid) then
			WAR.QQSH2 = 1
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·画地为牢"
			else
				WAR.Person[id]["特效文字3"] = "画地为牢"
			end
		end

		--30%几率大冰封
		if JLSD(30, 60, pid) then
			WAR.QQSH2 = 2
			if WAR.Person[id]["特效文字3"] ~= nil then
				WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·江山如画"
			else
				WAR.Person[id]["特效文字3"] = "江山如画"
			end
		end
	end

	--琴棋书画：倚天屠龙功，50%几率出特效，伤害提高20%，必封穴
	if wugong == 84 and QinqiSH(pid) and JLSD(20, 70, pid) then
		WAR.QQSH3 = 1
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "·秉笔直书"
		else
			WAR.Person[id]["特效文字3"] = "秉笔直书"
		end
	end

	--主运玉女：夭矫空碧，连击伤害杀气不减
	if Curr_NG(pid, 154) and WAR.ACT > 1 and JLSD(30, 60 + JY.Base["天书数量"]*2, pid) then
		WAR.YNXJ = 1
		if WAR.Person[id]["特效文字0"] ~= nil then
			WAR.Person[id]["特效文字0"] = WAR.Person[id]["特效文字0"] .. "+夭矫空碧"
		else
			WAR.Person[id]["特效文字0"] = "夭矫空碧"
		end
    end

    --怒气暴发

	if IsAlone(id) then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+孤注一掷"
		else
			WAR.Person[id]["特效文字3"] = "孤注一掷"
		end
    end

	if GetWarMap(WAR.Person[id]["坐标X"], WAR.Person[id]["坐标Y"], 6) == 2 then
		WAR.Person[id]["特效动画"] = 6
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = WAR.Person[id]["特效文字3"] .. "+八卦正位"
		else
			WAR.Person[id]["特效文字3"] = "八卦正位"
		end
	end --红色

	--全真七子，天罡北斗阵，文字显示
	if WAR.ZDDH == 73 then
		if (pid >= 123 and pid <= 128) or pid == 68 then
			WAR.Person[id]["特效动画"] = 93
			if WAR.Person[id]["特效文字2"] ~= nil then
				WAR.Person[id]["特效文字2"] = WAR.Person[id]["特效文字2"] .. "+天罡北斗阵加力"
			else
				WAR.Person[id]["特效文字2"] = "天罡北斗阵加力"
			end
		end
	end

    --蓄力攻击
    if WAR.Actup[pid] ~= nil then
    	--主运龙象或蛤蟆，追加杀气
		if Curr_NG(pid, 103) or Curr_NG(pid, 95) then
			ng = ng + 1200
		else
			ng = ng + 600
		end
		local str = "蓄力攻击"
		if WAR.SLSX[pid] ~= nil then
			str = str .. "·十龙十象"
		end
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = WAR.Person[id]["特效文字1"] .. "+"..str
		else
			WAR.Person[id]["特效文字1"] = str
		end
    end

    --九阴神功加力时，使用九阴白骨爪出九阴神爪
	if wugong == 11 and WAR.NGJL == 107 then
		ng = ng + 2000
		WAR.WS = 1
		if WAR.Person[id]["特效文字3"] ~= nil then
			WAR.Person[id]["特效文字3"] = "九阴神爪·"..WAR.Person[id]["特效文字3"]
		else
			WAR.Person[id]["特效文字3"] = "九阴神爪"
		end
	end

    --特效文字1，动画为红色圈
    if WAR.Person[id]["特效文字1"] ~= nil and WAR.Person[id]["特效动画"] == -1 then
		WAR.Person[id]["特效动画"] = 88
    end

	--北斗七闪的特效动画
	if match_ID(pid, 129) and WAR.CYZX[pid] ~= nil and WAR.BDQS > 0 then
		WAR.Person[id]["特效动画"] = 126
	end

	--无酒不欢的特效动画
	if pid == 0 and JY.Base["特殊"] == 1 then
		WAR.Person[id]["特效动画"] = 132
	end

	--苗人凤破军的动画和文字
	if match_ID(pid, 3) and WAR.MRF == 1 then
		if WAR.Person[id]["特效文字1"] ~= nil then
			WAR.Person[id]["特效文字1"] = "破军·"..WAR.Person[id]["特效文字1"]
		else
			WAR.Person[id]["特效文字1"] = "破军"
		end
		WAR.Person[id]["特效动画"] = 146
	end

    --无酒不欢：独孤求败的先手反击
	if WAR.ACT == 1 then
		local hit_DGQB;
		for i = 0, CC.WarWidth - 1 do
			for j = 0, CC.WarHeight - 1 do
				local effect = GetWarMap(i, j, 4)
				if 0 < effect then
					local emeny = GetWarMap(i, j, 2)
					if emeny >= 0 and emeny ~= WAR.CurID then
						if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] and match_ID(WAR.Person[emeny]["人物编号"], 592) then
							hit_DGQB = emeny
							break;
						end
					end
				end
			end
			if hit_DGQB ~= nil then
				break;
			end
		end

		if hit_DGQB ~= nil then
			local pre_target_list = {}
			local pre_target_num = 0
			local tx_1 = WAR.Person[id]["特效文字0"] or nil
			local tx_2 = WAR.Person[id]["特效文字1"] or nil
			local tx_3 = WAR.Person[id]["特效文字2"] or nil
			local tx_4 = WAR.Person[id]["特效文字3"] or nil
			local tx_5 = WAR.Person[id]["特效文字4"] or nil
			local tx_6 = WAR.Person[id]["特效动画"]
			WAR.Person[id]["特效文字0"] = nil
			WAR.Person[id]["特效文字1"] = nil
			WAR.Person[id]["特效文字2"] = nil
			WAR.Person[id]["特效文字3"] = nil
			WAR.Person[id]["特效文字4"] = nil
			WAR.Person[id]["特效动画"] = -1
			WAR.hit_DGQB = 1
			WAR.Person[hit_DGQB]["特效动画"] = 83
			for i = 0, CC.WarWidth - 1 do
				for j = 0, CC.WarHeight - 1 do
					local pre_effect = GetWarMap(i, j, 4)
					if pre_effect > 0 then
						local pre_target = GetWarMap(i, j, 2)
						pre_target_num = pre_target_num + 1
						pre_target_list[pre_target_num] = {i, j, pre_target, pre_effect}
					end
				end
			end
			CleanWarMap(4, 0)
			local s1 = WAR.CurID
			WAR.CurID = hit_DGQB
			WAR.Effect = 2
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[i]["死亡"] == false then
					local pid = WAR.Person[WAR.CurID]["人物编号"]
					local eid = WAR.Person[i]["人物编号"]
					local dam;
					dam = First_strike_dam_DG(pid, eid)
					if dam > 0 then
						WAR.Person[i]["生命点数"] = (WAR.Person[i]["生命点数"] or 0) - dam
						--无酒不欢：记录人物血量
						WAR.Person[i]["Life_Before_Hit"] = JY.Person[eid]["生命"]
						JY.Person[eid]["生命"] = JY.Person[eid]["生命"] - dam
						if JY.Person[eid]["生命"] < 0 then
							JY.Person[eid]["生命"] = 0
						end
						SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 4, 2)
					end
				end
			end
			War_ShowFight(WAR.Person[hit_DGQB]["人物编号"], 0, 0, 0, 0, 0, 60, -1)
			WAR.hit_DGQB = 0
			WAR.Person[hit_DGQB]["特效动画"] = -1

			--如果被上一步反击死亡，那么该人物的攻击就结束了
			if JY.Person[WAR.Person[s1]["人物编号"]]["生命"] <= 0 then
				return 1
			else
				WAR.CurID = s1
				CleanWarMap(4, 0)
				WAR.Effect = 0
				for i = 1, pre_target_num do
					SetWarMap(pre_target_list[i][1], pre_target_list[i][2], 2, pre_target_list[i][3])
					SetWarMap(pre_target_list[i][1], pre_target_list[i][2], 4, pre_target_list[i][4])
				end
				WAR.Person[id]["特效文字0"] = tx_1
				WAR.Person[id]["特效文字1"] = tx_2
				WAR.Person[id]["特效文字2"] = tx_3
				WAR.Person[id]["特效文字3"] = tx_4
				WAR.Person[id]["特效文字4"] = tx_5
				WAR.Person[id]["特效动画"] =  tx_6
			end
		end
	end

	--李秋水无相转身，没有触发过，或者分身已死，才可触发，有30%几率触发
	if (WAR.WXFS == nil or (WAR.WXFS ~= nil and WAR.Person[WAR.WXFS]["死亡"] == true)) and math.random(10) < 4 then
		local lqs_WXZS;
		for i = 0, CC.WarWidth - 1 do
			for j = 0, CC.WarHeight - 1 do
				local effect = GetWarMap(i, j, 4)
				if 0 < effect then
					local emeny = GetWarMap(i, j, 2)
					if emeny >= 0 and emeny ~= WAR.CurID then
						--仅限畅想主角触发
						if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] and match_ID(WAR.Person[emeny]["人物编号"], 118) and WAR.Person[emeny]["人物编号"] == 0 then
							lqs_WXZS = emeny
							SetWarMap(i, j, 4, 0)
							break;
						end
					end
				end
			end
		end

		if lqs_WXZS ~= nil then

			--ID临时交给李秋水
			local s = WAR.CurID
			WAR.CurID = lqs_WXZS
			local wxlox, wxloy;
			War_CalMoveStep(WAR.CurID, 10, 0)
			local function SelfXY(x, y)
				local yes = 0
				if x == WAR.Person[WAR.CurID]["坐标X"] then
					yes = yes +1
				end
				if y == WAR.Person[WAR.CurID]["坐标Y"] then
					yes = yes +1
				end
				if yes == 2 then
					return true
				end
				return false
			end
	        local x, y = nil, nil
	        while true do
				x, y = War_SelectMove()
				if x ~= nil then
					WAR.ShowHead = 0
					wxlox, wxloy = x, y
					break;
				--ESC退出
				else
					WAR.ShowHead = 0
					x, y = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
					--wxlox, wxloy = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
					break;
				end
			end
			--不在自身位置才能触发幻象
			if SelfXY(x, y) == false then
				SetWarMap(wxlox, wxloy, 4, 0)
				--本场还没触发过无相转身，则加入新人物
				if WAR.WXFS == nil then
					WAR.Person[WAR.PersonNum]["人物编号"] = 600
					WAR.Person[WAR.PersonNum]["我方"] = WAR.Person[WAR.CurID]["我方"]
					WAR.Person[WAR.PersonNum]["坐标X"] = wxlox
					WAR.Person[WAR.PersonNum]["坐标Y"] = wxloy
					WAR.Person[WAR.PersonNum]["死亡"] = false
					WAR.Person[WAR.PersonNum]["人方向"] = WAR.Person[WAR.CurID]["人方向"]
					WAR.Person[WAR.PersonNum]["贴图"] = WarCalPersonPic(WAR.PersonNum)
					lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[600]["头像代号"]), string.format(CC.FightPicFile[2], JY.Person[600]["头像代号"]), 4 + WAR.PersonNum)
					WAR.tmp[5000+WAR.PersonNum] = JY.Person[600]["头像代号"]
					WAR.JQSDXS[600] = 0	--直接指定集气，以免召唤出来马上被斗转跳出
					WAR.WXFS = WAR.PersonNum
					WAR.PersonNum = WAR.PersonNum + 1
				--已经触发过，则让分身复活
				else
					WAR.Person[WAR.WXFS]["死亡"] = false
					WAR.Person[WAR.WXFS]["我方"] = WAR.Person[WAR.CurID]["我方"]
					WAR.Person[WAR.WXFS]["坐标X"] = wxlox
					WAR.Person[WAR.WXFS]["坐标Y"] = wxloy
					WAR.Person[WAR.WXFS]["人方向"] = WAR.Person[WAR.CurID]["人方向"]
					WAR.Person[WAR.WXFS]["贴图"] = WarCalPersonPic(WAR.WXFS)
					JY.Person[600]["生命"] = JY.Person[600]["生命最大值"]
					JY.Person[600]["内力"] = JY.Person[600]["内力最大值"]
					JY.Person[600]["体力"] = 100
					JY.Person[600]["受伤程度"] = 0
					JY.Person[600]["中毒程度"] = 0
					JY.Person[600]["冰封程度"] = 0
					JY.Person[600]["灼烧程度"] = 0
					WAR.Person[WAR.WXFS].Time = 0
					--流血
					if WAR.LXZT[600] ~= nil then
						WAR.LXZT[600] = nil
					end
					--封穴
					if WAR.FXDS[600] ~= nil then
						WAR.FXDS[600] = nil
					end
				end

				--清除自身位置贴图
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)

				--修改自身与幻象坐标
				WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], WAR.Person[WAR.WXFS]["坐标X"], WAR.Person[WAR.WXFS]["坐标Y"] = WAR.Person[WAR.WXFS]["坐标X"], WAR.Person[WAR.WXFS]["坐标Y"],WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]

				--增加幻象贴图
				SetWarMap(WAR.Person[WAR.WXFS]["坐标X"], WAR.Person[WAR.WXFS]["坐标Y"], 5, WAR.Person[WAR.WXFS]["贴图"])
				SetWarMap(WAR.Person[WAR.WXFS]["坐标X"], WAR.Person[WAR.WXFS]["坐标Y"], 2, WAR.WXFS)

				--增加自身贴图
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
			end
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 90,1,"无相转身")

			--还原ID并打断连击
			WAR.CurID = s
			WAR.ACT = 10
		end
	end

    --计算伤害的敌人
    for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			lib.GetKey()
			local effect = GetWarMap(i, j, 4)
			if 0 < effect then
				local emeny = GetWarMap(i, j, 2)
				if 0 <= emeny and emeny ~= WAR.CurID then		--如果有人，并且不是当前控制人
					--触发逆转乾坤的情况下，无误伤特效和合击依然会打到自己人
					if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] or (ZHEN_ID < 0 and WAR.WS == 0) or WAR.NZQK > 0 then
						if JY.Wugong[wugong]["伤害类型"] == 1 and (fightscope == 0 or fightscope == 3) then
							if level == 11 then
								level = 10
							end
							--无酒不欢：这里需要完善修改
							--WAR.Person[emeny]["内力点数"] = (WAR.Person[emeny]["内力点数"] or 0) - War_WugongHurtNeili(emeny, wugong, level)
							SetWarMap(i, j, 4, 3)
							WAR.Effect = 3
						else
							--林朝英轻云蔽月，每50时序可触发一次，免疫伤害10时序，误伤不触发
							if match_ID(WAR.Person[emeny]["人物编号"], 605) and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] then
								if WAR.QYBY[WAR.Person[emeny]["人物编号"]] == nil then
									WAR.QYBY[WAR.Person[emeny]["人物编号"]] = 50
								end
								if WAR.QYBY[WAR.Person[emeny]["人物编号"]] > 40 then
									WAR.Person[emeny]["特效文字3"] = "轻云蔽月"
									WAR.Person[emeny]["特效动画"] = 102
								else
									WAR.Person[emeny]["生命点数"] = (WAR.Person[emeny]["生命点数"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(i, j, 4, 2)
								end
							--主角觉醒后，喵姐开局前三次不受伤害
							elseif match_ID(WAR.Person[emeny]["人物编号"], 92) and JY.Person[0]["六如觉醒"] > 0 and WAR.FF < 3 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] then
								WAR.FF = WAR.FF + 1
								WAR.Person[emeny]["特效动画"] = 135
							--黛绮丝倾国
							elseif WAR.QGZT[WAR.Person[emeny]["人物编号"]] ~= nil and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] then
								local list = {}
								for q = 0, WAR.PersonNum - 1 do
									if WAR.Person[q]["死亡"] == false and q ~= WAR.CurID and WAR.Person[q]["我方"] ~= WAR.Person[emeny]["我方"] then
										table.insert(list,q)
									end
								end
								local F_target
								if list[1] ~= nil then
									WAR.Person[emeny]["特效动画"] = 149
									F_target = list[math.random(#list)]
									WAR.NZQK = 3
									WAR.Person[F_target]["生命点数"] = (WAR.Person[F_target]["生命点数"] or 0) - War_WugongHurtLife(F_target, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(WAR.Person[F_target]["坐标X"], WAR.Person[F_target]["坐标Y"], 4, 2)
									WAR.NZQK = 0
								else
									WAR.Person[emeny]["生命点数"] = (WAR.Person[emeny]["生命点数"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(i, j, 4, 2)
								end
								--无论是否有第三方，既无论是否反弹，都消耗一次次数
								WAR.QGZT[WAR.Person[emeny]["人物编号"]] = WAR.QGZT[WAR.Person[emeny]["人物编号"]] -1
								if WAR.QGZT[WAR.Person[emeny]["人物编号"]] < 1 then
									WAR.QGZT[WAR.Person[emeny]["人物编号"]] = nil
								end
							else
								WAR.Person[emeny]["生命点数"] = (WAR.Person[emeny]["生命点数"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
								WAR.Effect = 2
								SetWarMap(i, j, 4, 2)
							end
							--沉睡状态的敌人会醒来
							if WAR.CSZT[WAR.Person[emeny]["人物编号"]] ~= nil then
								WAR.CSZT[WAR.Person[emeny]["人物编号"]] = nil
							end
						end
					end
				end
			end
		end
    end

	--无酒不欢：标主的大招音效
    local dhxg = JY.Wugong[wugong]["武功动画&音效"]
    if WAR.LXZQ == 1 then
		dhxg = 71
    elseif WAR.JSYX == 1 then
        dhxg = 84
    elseif WAR.ASKD == 1 then
        dhxg = 65
    elseif WAR.GCTJ == 1 then
        dhxg = 108
    elseif WAR.JSTG == 1 then
        dhxg = 119
    end

	--狄云赤心连城追加连击
	if WAR.CXLC == 1 and WAR.CXLC_Count < 3 then
		fightnum = fightnum + 1
		WAR.CXLC_Count = WAR.CXLC_Count + 1
	end

	--血刀吸血，上限100点
	if WAR.XDLeech > 0 then
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", WAR.XDLeech);
	end

	--韦一笑吸血10%，上限100点
	if WAR.WYXLeech > 0 then
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", WAR.WYXLeech);
	end

	--天魔功吸血20%
	if WAR.TMGLeech > 0 then
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", WAR.TMGLeech);
	end

	--血河神鉴吸血，上限100点
	if WAR.XHSJ > 0 then
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", WAR.XHSJ);
	end

	--无酒不欢：人物的攻击动画和点数显示
	War_ShowFight(pid, wugong, JY.Wugong[wugong]["武功类型"], level, x, y, dhxg, ZHEN_ID)

	--无明业火状态，耗损使用的内力一半的生命
	if WAR.WMYH[pid] ~= nil then
		CurIDTXDH(WAR.CurID, 127,1, "无明业火", C_ORANGE)
		local nlDam = math.modf((math.modf((level + 3) / 2) * JY.Wugong[wugong]["消耗内力点数"])/2)
		WAR.Person[WAR.CurID]["生命点数"] = (WAR.Person[WAR.CurID]["生命点数"] or 0) + AddPersonAttrib(pid, "生命", -nlDam)
	    --至少留1滴血
	    if JY.Person[pid]["生命"] <= 0 then
			JY.Person[pid]["生命"] = 1
	    end
	end

	War_Show_Count(WAR.CurID);		--显示当前控制人的点数

	WAR.TFBW = 0		--听风辨位的文字记录恢复
	WAR.TLDWX = 0		--天罗地网的文字记录恢复

    WAR.Person[WAR.CurID]["经验"] = WAR.Person[WAR.CurID]["经验"] + 2

    --[[我方，消耗的内力
    if WAR.Person[WAR.CurID]["我方"] then
		local nl = nil

		nl = math.modf((level + 3) / 2) * JY.Wugong[wugong]["消耗内力点数"]

		--纯阳减少内力消耗
		--主运
		if Curr_NG(pid, 99) then
			nl = math.modf(nl*0.4);
		--被动
		elseif PersonKF(pid, 99) then
			nl = math.modf(nl*0.5);
		end

		--阳内主运九阳，减少70%耗内
		if Curr_NG(pid, 106) and (JY.Person[pid]["内力性质"] == 1 or (pid == 0 and JY.Base["标准"] == 6)) then
			nl = math.modf(nl*0.3);
		end

		--乔峰降龙消耗减半
		if match_ID(pid, 50) and wugong == 26 then
			nl = math.modf(nl/2);
		end

		--段誉六脉消耗减半
		if match_ID(pid, 53) and wugong == 49 then
			nl = math.modf(nl/2);
		end

		--指法主角六脉消耗减半
		if pid == 0 and JY.Base["标准"] == 2 and wugong == 49 then
			nl = math.modf(nl/2);
		end

		--天外攻击，只消耗一半内力
		if Given_WG(pid, wugong) then
			nl = math.modf(nl/2);
		end

		AddPersonAttrib(pid, "内力", -(nl))
	--NPC的耗内
	else
		AddPersonAttrib(pid, "内力", -math.modf((level + 3) / 2) * JY.Wugong[wugong]["消耗内力点数"]/7*2)
    end]]

    if JY.Person[pid]["内力"] < 0 then
		JY.Person[pid]["内力"] = 0
    end

    if JY.Person[pid]["生命"] <= 0 then
		break;
    end


	--无酒不欢：被杀气的动态显示
  	DrawTimeBar2()

	--太极拳，借力打力，蓄力清除
	--张三丰不清除
	if wugong == 16 and WAR.tmp[3000 + pid] ~= nil and WAR.tmp[3000 + pid] > 0 and match_ID(pid, 5) == false then
		WAR.tmp[3000 + pid] = 0
	end

	WAR.ACT = WAR.ACT + 1   --统计攻击次数累加1

  	--蓝烟清：攻击范围内的敌人全部死亡时取消连击
  	local flag = 0;
  	local n = 0;
    for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			lib.GetKey()
			local effect = GetWarMap(i, j, 4)
			if 0 < effect then
				local emeny = GetWarMap(i, j, 2)
				if 0 <= emeny and WAR.Person[id]["我方"] ~= WAR.Person[emeny]["我方"] then
					n = n + 1;
					if JY.Person[WAR.Person[emeny]["人物编号"]]["生命"] > 0 then
						flag = 1;
					end
				end
    		end
    	end
    end

	--无酒不欢：程灵素不会中断连击
    if flag == 0 and n > 0 and match_ID(pid, 2) == false then
    	break;
    end

	--主运太极神功，太极之形增加连击
	if Curr_NG(pid, 171) and WAR.TJZX[pid] ~= nil and WAR.TJZX[pid] >= 5 then
		fightnum = fightnum + 1
		WAR.TJZX[pid] = WAR.TJZX[pid] - 5
		WAR.TJZX_LJ = 1
	end

  end

	--连击结束
	if JY.Restart == 1 then
		return 1
	end

	--天外连击判定取消
	WAR.TWLJ = 0

	--黯然极意范围恢复
	WAR.ARJY = 0

	--狄云赤心连城计数恢复
	WAR.CXLC_Count = 0

	--太极拳，借力打力，蓄力清除
	--张三丰在这里清除
	if wugong == 16 and WAR.tmp[3000 + pid] ~= nil and WAR.tmp[3000 + pid] > 0 and match_ID(pid, 5) then
		WAR.tmp[3000 + pid] = 0
	end

	--如果触发了逆转乾坤的强化反弹效果，在这里恢复
	if WAR.NZQK > 0 then
		WAR.NZQK = 0
	end

	--计算消耗的体力
	local jtl = 1

	--攻击消耗体力
	AddPersonAttrib(pid, "体力", -jtl);

	--斗转星移计算，现在人人能反击，好时代来临力
	if WAR.Person[WAR.CurID]["反击武功"] ~= 9999 then
	local dz = {}
	local dznum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["反击武功"] ~= -1 and WAR.Person[i]["反击武功"] ~= 9999 then
			dznum = dznum + 1
			dz[dznum] = {i, WAR.Person[WAR.CurID]["坐标X"] - WAR.Person[i]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] - WAR.Person[i]["坐标Y"]}
			WAR.Person[i]["反击武功"] = 9999
		end
	end
	for i = 1, dznum do
		local rid = WAR.Person[dz[i][1]]["人物编号"]
		local kongfuid = JY.Person[rid]["主运内功"]
		
		local datas = GetValidTargets(dz[i][1], kongfuid)
		--JY.Person[rid]["姓名"] = dz[i][2].."猪头"..dz[i][3]
		local data = {}
		data.x, data.y = dz[i][2], dz[i][3]
		if Contains(datas, data) then
			local tmp = WAR.CurID
			WAR.CurID = dz[i][1]
			WAR.DZXY = 1

			War_Fight_Sub(dz[i][1], kongfuid + 100, WAR.Person[tmp]["坐标X"], WAR.Person[tmp]["坐标Y"])
			
			WAR.CurID = tmp
			WAR.DZXY = 0
		end
		WAR.Person[dz[i][1]]["反击武功"] = -1
	end
	end

	return 1;
end

function Contains(targets, target)
	if targets == nil then
		return false
	end
	for i = 1, #targets do
		if targets[i].x == target.x and targets[i].y == target.y then
			return true
		end
	end
	return false
end

function GetNonEmptyTargets(warid, targets, xx, yy)
	if targets == nil then
		return
	end
	local pid = WAR.Person[warid]["人物编号"]
	if xx == nil then
		xx = 0
	end
	if yy == nil then
		yy = 0
	end
	--xx = xx + WAR.Person[warid]["坐标X"]
	--yy = yy + WAR.Person[warid]["坐标Y"]
	local targets2 = {}
	local targets2index = 0
	for i = 1, #targets do
		local mid = GetWarMap(targets[i].x + xx, targets[i].y + yy, 2)
		if mid ~= nil and mid >= 0 and WAR.Person[warid]["我方"] ~= WAR.Person[mid]["我方"] then
			targets2index = targets2index + 1
			targets2[targets2index] = {}
			targets2[targets2index].x = targets[i].x
			targets2[targets2index].y = targets[i].y
		end
	end
	return targets2
end

function GetValidTargets(warid, kungfuid)
	local pid = WAR.Person[warid]["人物编号"]
	if kungfuid == nil then
		kungfuid = JY.Person[pid]["主运内功"]
	end
	if kungfuid == 0 then
		return nil
	end
	local targets = {}
	local targetsindex = 0
	local m1, m2, m3, a1, a2 = WugongArea(kungfuid, 10)
	local distance = 0
	for i = -10, 10 do
		for j = -10, 10 do
			if m1 == 1 then
				if math.abs(i) > m3 and math.abs(i) <= m2 then
					targetsindex = targetsindex + 1
					targets[targetsindex] = {}
					targets[targetsindex].x = i
					targets[targetsindex].y = j
				end
			end
			if m1 == 0 then
				distance = math.abs(i) + math.abs(j)
				if distance > m3 and distance <= m2 then
					targetsindex = targetsindex + 1
					targets[targetsindex] = {}
					targets[targetsindex].x = i
					targets[targetsindex].y = j
				end
			end
			if m1 == 2 then
				distance = math.max(math.abs(i), math.abs(j))
				if math.min(math.abs(i), math.abs(j)) == 0 and distance > m3 and distance <= m2 then
					targetsindex = targetsindex + 1
					targets[targetsindex] = {}
					targets[targetsindex].x = i
					targets[targetsindex].y = j
				end
			end
		end
	end

	return targets
end

--无酒不欢：选择移动
--增加7*7的显示flag
function War_SelectMove(flag)
	local x0 = WAR.Person[WAR.CurID]["坐标X"]
	local y0 = WAR.Person[WAR.CurID]["坐标Y"]
	local x = x0
	local y = y0
	if flag ~= nil then
		CleanWarMap(7, 0)
	end
	while true do
		if JY.Restart == 1 then
			break
		end
		local x2 = x
		local y2 = y
		WarDrawMap(1, x, y)

		if flag ~= nil then
			for i = 1, 4 do
				for j = 1, 4 do
					SetWarMap(x + i - 1, y + j - 1, 7, 1)
					SetWarMap(x - i + 1, y + j - 1, 7, 1)
					SetWarMap(x + i - 1, y - j + 1, 7, 1)
					SetWarMap(x - i + 1, y - j + 1, 7, 1)
				end
			end
			WarDrawMap(1, x, y)
		end

		WarShowHead(GetWarMap(x, y, 2))

		--如阴时显示集气条
		if WAR.FLHS5 == 2 then
			DrawTimeBar_sub()
		end

		ShowScreen()

		if flag ~= nil then
			CleanWarMap(7, 0)
		end

		local key, ktype, mx, my = WaitKey(1)
		if key == VK_UP then
			y2 = y - 1
		elseif key == VK_DOWN then
			y2 = y + 1
		elseif key == VK_LEFT then
			x2 = x - 1
		elseif key == VK_RIGHT then
			x2 = x + 1
		elseif key == VK_SPACE or key == VK_RETURN then
			return x, y
		elseif key == VK_ESCAPE or ktype == 4 then
			return nil
		elseif ktype == 2 or ktype == 3 then
			mx = mx - CC.ScreenW / 2
			my = my - CC.ScreenH / 2
			mx = (mx) / CC.XScale
			my = (my) / CC.YScale
			mx, my = (mx + my) / 2, (my - mx) / 2
			if mx > 0 then
				mx = mx + 0.99
			else
				mx = mx - 0.01
			end
			if my > 0 then
				my = my + 0.99
			else
				mx = mx - 0.01
			end
			mx = math.modf(mx)
			my = math.modf(my)
			for i = 0, 10 do
				if mx + i <= 63 then
					if my + i > 63 then
						break;
					end
				end
				local hb = GetS(JY.SubScene, x0 + mx + i, y0 + my + i, 4)

				if math.abs(hb - CC.YScale * i * 2) < 5 then
					mx = mx + i
					my = my + i
				end
			end
			x2, y2 = mx + x0, my + y0

			if ktype == 3 then
				return x, y
			end
		end

		--无酒不欢：避免跳出
		if GetWarMap(x2, y2, 3) ~= nil and GetWarMap(x2, y2, 3) < 128 then
			x = x2
			y = y2
		end
	end
end

--获取武功最小内力
function War_GetMinNeiLi(pid)
	local minv = math.huge
	for i = 1, CC.Kungfunum do
		local tmpid = JY.Person[pid]["武功" .. i]
		if tmpid > 0 and JY.Wugong[tmpid]["消耗内力点数"] < minv then
			minv = JY.Wugong[tmpid]["消耗内力点数"]
		end
	end
	return minv
end

--无酒不欢：手动战斗菜单上级
function War_Manual()
	local r = nil
	local x, y, move, pic, face_dir = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], WAR.Person[WAR.CurID]["移动步数"], WAR.Person[WAR.CurID]["贴图"], WAR.Person[WAR.CurID]["人方向"]
	while true do
		if JY.Restart == 1 then
			break
		end
		WAR.ShowHead = 1
		r = War_Manual_Sub()
		--移动，这里实际返回的应该是-1
		if r == 1 or r == -1 then
			--WAR.Person[WAR.CurID]["移动步数"] = 0 
		--ESC返回
		elseif r == 0 then
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
			WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], WAR.Person[WAR.CurID]["移动步数"] = x, y, move
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, pic)
			--无酒不欢：人物面相也要还原
			WAR.Person[WAR.CurID]["人方向"] = face_dir
		elseif r == 20 then

		else
			break;
		end
	end
	WAR.ShowHead = 0
	WarDrawMap(0)
	return r	--无酒不欢：这里的返回值似乎没什么屌用
end

--手动战斗菜单
function War_Manual_Sub()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	--local isEsc = 0
	local warmenu = {
	{"移动", War_MoveMenu, 1},	--1
	{"攻击", War_FightMenu, 1},	--2
	{"运功", War_YunGongMenu, 1},	--3
	{"战术", War_TacticsMenu, 1},	--4
	{"用毒", War_PoisonMenu, 1},	--5
	{"解毒", War_DecPoisonMenu, 1},	--6
	{"医疗", War_DoctorMenu, 1},	--7
	{"物品", War_ThingMenu, 1},	--8
	{"状态", War_StatusMenu, 1},	--9
	{"休息", War_RestMenu, 1},	--10
	{"特色", War_TgrtsMenu, 1},	--11
	{"撤退", War_Retreat, 1},	--12
	{"自动", War_AutoMenu, 1}	--13
	}

	--特色指令
	if JY.Person[pid]["特色指令"] == 1 then
		--如果是畅想
		if pid == 0 then
			warmenu[11][1] = GRTS[JY.Base["畅想"]]
		else
			warmenu[11][1] = GRTS[pid]
		end
	else
		warmenu[11][3] = 0
	end

	--虚竹
	if match_ID(pid, 49) then
		--如果没有中生死符的人物则不显示特色指令
		local t = 0
		for i = 0, WAR.PersonNum - 1 do
			local wid = WAR.Person[i]["人物编号"]
			if WAR.TZ_XZ_SSH[wid] == 1 and WAR.Person[i]["死亡"] == false then
				t = 1
			end
		end
		if t == 0 then
			warmenu[11][3] = 0
		end
		--体力小于20不显示特色指令
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--祖千秋
	if match_ID(pid, 88) then
		--如果周围没有队友不显示特色指令
		local yes = 0
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["我方"] == true and WAR.Person[i]["死亡"] == false and RealJL(WAR.CurID, i, 5) and i ~= WAR.CurID then
				yes = 1
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--体力小于20不显示特色指令
		--内力小于1000不显示
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--人厨子
	if match_ID(pid, 89) then
		--如果周围没有队友不显示特色指令
		local px, py = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
		local mxy = {
					{WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] + 1},
					{WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] - 1},
					{WAR.Person[WAR.CurID]["坐标X"] + 1, WAR.Person[WAR.CurID]["坐标Y"]},
					{WAR.Person[WAR.CurID]["坐标X"] - 1, WAR.Person[WAR.CurID]["坐标Y"]}}

		local yes = 0
		for i = 1, 4 do
			if GetWarMap(mxy[i][1], mxy[i][2], 2) >= 0 then
			local mid = GetWarMap(mxy[i][1], mxy[i][2], 2)
			if inteam(WAR.Person[mid]["人物编号"]) then
				yes = 1
				end
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--体力小于25不显示特色指令
		if JY.Person[pid]["体力"] < 25 then
			warmenu[11][3] = 0
		end
	end

	--张无忌
	if match_ID(pid, 9) then
		--如果周围没有队友不显示特色指令
		local yes = 0
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["我方"] == true and WAR.Person[i]["死亡"] == false and RealJL(WAR.CurID, i, 8) and i ~= WAR.CurID then
				yes = 1
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--体力小于20不显示特色指令
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--蓝烟清：霍青桐统率指令
	if match_ID(pid, 74) then
		--体力小于10不显示特色指令
		if JY.Person[pid]["体力"] < 10 or JY.Person[pid]["内力"] < 150 then
			warmenu[11][3] = 0
		end
	end

	--慕容复指令 幻梦
	if match_ID(pid, 51) then
		--体力小于20不显示特色指令
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--小昭指令 影步
	if match_ID(pid, 66) then
		--体力小于30，或内力小于2000不显示特色指令
		if JY.Person[pid]["体力"] < 30 or JY.Person[pid]["内力"] < 2000 then
			warmenu[11][3] = 0
		end
	end

	--钟灵指令 灵貂
	if match_ID(pid, 90) then
		--体力小于10不显示特色指令
		if JY.Person[pid]["体力"] < 10 then
			warmenu[11][3] = 0
		end
	end

	--喵姐指令 变装
	if match_ID(pid, 92) then
		--体力小于20不显示特色指令
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--胡斐指令 飞狐
	if match_ID(pid, 1) then
		--体力小于20不显示特色指令
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--鸠摩智指令 幻化
	if match_ID(pid, 103) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--达尔巴指令 死战
	if match_ID(pid, 160) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 or WAR.SZSD ~= -1 then
			warmenu[11][3] = 0
		end
	end

	--金轮 龙象
	if match_ID(pid, 62) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--黄蓉 遁甲
	if match_ID(pid, 56) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--韦小宝 口才
	if match_ID(pid, 601) then
		if JY.Person[pid]["体力"] < 30 then
			warmenu[11][3] = 0
		end
	end

	--苗人凤 破军
	if match_ID(pid, 3) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--何太冲 铁琴
	if match_ID(pid, 7) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--方证 金身
	if match_ID(pid, 149) then
		if JY.Person[pid]["体力"] < 20 or JY.Person[pid]["内力"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--阎基 虚弱
	if match_ID(pid, 4) then
		if JY.Person[pid]["体力"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--出左右时，移动，解毒，医疗，物品，特色，自动不可见
	if WAR.ZYHB == 2 then
		warmenu[1][3] = 0
		warmenu[6][3] = 0
		warmenu[7][3] = 0
		warmenu[8][3] = 0
		warmenu[11][3] = 0
		warmenu[13][3] = 0
	end

	--体力小于5或者已经移动过时，移动不可见
	if JY.Person[pid]["体力"] <= 5 or WAR.Person[WAR.CurID]["移动步数"] <= 0 then
		warmenu[1][3] = 0
		--isEsc = 1
	end

	--判断最小内力，是否可显示攻击
	local minv = War_GetMinNeiLi(pid)
	if JY.Person[pid]["内力"] < minv or JY.Person[pid]["体力"] < 10 then
		warmenu[2][3] = 0
	end

	--用毒解毒医疗，567
	if JY.Person[pid]["体力"] < 10 or JY.Person[pid]["用毒能力"] < 20 then
		warmenu[5][3] = 0
	end
	if JY.Person[pid]["体力"] < 10 or JY.Person[pid]["解毒能力"] < 20 then
		warmenu[6][3] = 0
	end
	if JY.Person[pid]["体力"] < 50 or JY.Person[pid]["医疗能力"] < 20 then
		warmenu[7][3] = 0
	end

	lib.GetKey()
	Cls()
	DrawTimeBar_sub()
	return ShowMenu(warmenu, #warmenu, 0, CC.MainMenuX, CC.MainMenuY, 0, 0, 1, 1, CC.DefaultFont, C_ORANGE, C_WHITE)
end

--无酒不欢：运功选择菜单
function War_YunGongMenu()
	local id = WAR.Person[WAR.CurID]["人物编号"]
	local menu={};
	menu[1]={"运行内功",SelectNeiGongMenu,1};
	menu[2]={"停运内功",nil,1};
	menu[3]={"运行轻功",SelectQingGongMenu,1};
	menu[4]={"停运轻功",nil,1};
    local r = ShowMenu(menu,#menu,0,CC.MainSubMenuX+15,CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if r == 2 then
		JY.Person[id]["主运内功"] = 0
		DrawStrBoxWaitKey(JY.Person[id]["姓名"].."停止了运行主内功",C_RED,CC.DefaultFont,nil,LimeGreen)
		return 20;
	elseif r == 20 then
		return 20;
	elseif r == 4 then
		JY.Person[id]["主运轻功"] = 0
		DrawStrBoxWaitKey(JY.Person[id]["姓名"].."停止了运行主轻功",M_DeepSkyBlue,CC.DefaultFont,nil,LimeGreen)
		return 20;
	elseif r == 10 then
		return 10;
	end
end

--无酒不欢：选择内功菜单
function SelectNeiGongMenu()
	local id, x1, y1 = WAR.Person[WAR.CurID]["人物编号"], WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
	local menu={};
	for i=1,CC.Kungfunum do
        menu[i]={JY.Wugong[JY.Person[id]["武功" .. i]]["名称"],nil,0};
		if JY.Wugong[JY.Person[id]["武功" .. i]]["武功类型"] == 6 then
			menu[i][3]=1;
		end
		--天罡不能运三大
		if id == 0 and JY.Base["标准"] == 6 and (JY.Person[id]["武功" .. i] == 106 or JY.Person[id]["武功" .. i] == 107 or JY.Person[id]["武功" .. i] == 108) then
			menu[i][3]=0;
		end
		--五岳剑诀不能运
		if JY.Person[id]["武功" .. i] == 175 then
			menu[i][3]=0
		end
	end
    local main_neigong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if main_neigong ~= nil and main_neigong > 0 then
		CleanWarMap(4, 0)
		SetWarMap(x1, y1, 4, 1)
		War_ShowFight(id, 0, 0, 0, 0, 0, 9)
		AddPersonAttrib(id, "内力", -200);
		AddPersonAttrib(id, "体力", -5);
		JY.Person[id]["主运内功"] = JY.Person[id]["武功" .. main_neigong]
		return 20;
	end
end

--无酒不欢：选择轻功菜单
function SelectQingGongMenu()
	local id, x1, y1 = WAR.Person[WAR.CurID]["人物编号"], WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
	local menu={};
	for i=1,CC.Kungfunum do
        menu[i]={JY.Wugong[JY.Person[id]["武功" .. i]]["名称"],nil,0};
		if JY.Wugong[JY.Person[id]["武功" .. i]]["武功类型"] == 7 then
			menu[i][3]=1;
		end
	end
    local main_qinggong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if main_qinggong ~= nil and main_qinggong > 0 then
		CleanWarMap(4, 0)
		SetWarMap(x1, y1, 4, 1)
		War_ShowFight(id, 0, 0, 0, 0, 0, 9)
		AddPersonAttrib(id, "体力", -10);
		WAR.YQG = 1
		JY.Person[id]["主运轻功"] = JY.Person[id]["武功" .. main_qinggong]
		return 10;
	end
end

--无酒不欢：战术菜单
function War_TacticsMenu()
	local menu={};
	menu[1]={"蓄力",nil,1};
	menu[2]={"防御",nil,1};
	menu[3]={"等待",nil,1};
    local r = ShowMenu(menu,#menu,0,CC.MainSubMenuX+15,CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	--蓄力
	if r == 1 then
		return War_ActupMenu()
	--防御
	elseif r == 2 then
		return War_DefupMenu()
	--等待
	elseif r == 3 then
		return War_Wait()
	--快捷键的额外判定
	elseif r == 4 then
		return 1
	end
end

function PushBack(warid, time)
	--lib.Debug("push"..time)
	if time == 0 then
		return
	end
	local ownTime = WAR.Person[warid].Time
	local target = -1
	local targetTime = -9999
	for j = 0, WAR.PersonNum - 1 do
		if WAR.Person[j]["死亡"] == false and targetTime < WAR.Person[j].Time and WAR.Person[j].Time < ownTime then
			target = j
			targetTime = WAR.Person[j].Time
		end
	end
	if target == -1 then
		--已经是倒数第一
		return
	end
	--lib.Debug(WAR.Person[target]["人物编号"])
	WAR.Person[warid].Time, WAR.Person[target].Time = WAR.Person[target].Time, WAR.Person[warid].Time
	if WAR.Person[warid]["我方"] ~= WAR.Person[target]["我方"] then
		PushBack(warid, time - 1)
	else
		PushBack(warid, time)
	end
end
--修炼武功
function War_PersonTrainBook(pid)
  local p = JY.Person[pid]
  local thingid = p["修炼物品"]
  if thingid < 0 then
    return
  end
  JY.Thing[101]["加御剑能力"] = 1
  JY.Thing[123]["加拳掌功夫"] = 1
  local wugongid = JY.Thing[thingid]["练出武功"]
  local wg = 0
  if JY.Person[pid]["武功12"] > 0 and wugongid >= 0 then
    for i = 1, CC.Kungfunum do
      if JY.Thing[thingid]["练出武功"] == JY.Person[pid]["武功" .. i] then
        wg = 1
      end
    end
  if wg == 0 then		--修复第一版本，不可修炼武功的BUG
  	return
	end
  end


	local yes1, yes2, kfnum = false, false, nil
	while true do
		local needpoint = TrainNeedExp(pid)
		if needpoint <= p["修炼点数"] then
			yes1 = true
			AddPersonAttrib(pid, "生命最大值", JY.Thing[thingid]["加生命最大值"])
			--修炼血刀减少生命
			--狄云不减
			if thingid == 139 and match_ID(pid, 37) == false then
				AddPersonAttrib(pid, "生命最大值", -15)
				AddPersonAttrib(pid, "生命", -15)
				if JY.Person[pid]["生命最大值"] < 1 then
					JY.Person[pid]["生命最大值"] = 1
				end
			end
			if JY.Person[pid]["生命"] < 1 then
				JY.Person[pid]["生命"] = 1
			end
			--主角练小无不调和
			if JY.Thing[thingid]["改变内力性质"] == 2 then
				if thingid == 75 then
					if pid ~= 0 then
						p["内力性质"] = 2
					end
				else
					p["内力性质"] = 2
				end
			end

			AddPersonAttrib(pid, "内力最大值", JY.Thing[thingid]["加内力最大值"])
			AddPersonAttrib(pid, "攻击力", JY.Thing[thingid]["加攻击力"])
			AddPersonAttrib(pid, "轻功", JY.Thing[thingid]["加轻功"])
			AddPersonAttrib(pid, "防御力", JY.Thing[thingid]["加防御力"])
			AddPersonAttrib(pid, "医疗能力", JY.Thing[thingid]["加医疗能力"])
			AddPersonAttrib(pid, "用毒能力", JY.Thing[thingid]["加用毒能力"])
			AddPersonAttrib(pid, "解毒能力", JY.Thing[thingid]["加解毒能力"])
			AddPersonAttrib(pid, "抗毒能力", JY.Thing[thingid]["加抗毒能力"])
			if match_ID(pid, 56) or match_ID(pid, 77) then		--黄蓉 萧中慧 双倍兵器值
				AddPersonAttrib(pid, "拳掌功夫", JY.Thing[thingid]["加拳掌功夫"] * 2)
				AddPersonAttrib(pid, "指法技巧", JY.Thing[thingid]["加指法技巧"] * 2)
				AddPersonAttrib(pid, "御剑能力", JY.Thing[thingid]["加御剑能力"] * 2)
				AddPersonAttrib(pid, "耍刀技巧", JY.Thing[thingid]["加耍刀技巧"] * 2)
				AddPersonAttrib(pid, "特殊兵器", JY.Thing[thingid]["加特殊兵器"] * 2)
			else
				AddPersonAttrib(pid, "拳掌功夫", JY.Thing[thingid]["加拳掌功夫"])
				AddPersonAttrib(pid, "指法技巧", JY.Thing[thingid]["加指法技巧"])
				AddPersonAttrib(pid, "御剑能力", JY.Thing[thingid]["加御剑能力"])
				AddPersonAttrib(pid, "耍刀技巧", JY.Thing[thingid]["加耍刀技巧"])
				AddPersonAttrib(pid, "特殊兵器", JY.Thing[thingid]["加特殊兵器"])
			end

			AddPersonAttrib(pid, "暗器技巧", JY.Thing[thingid]["加暗器技巧"])
			AddPersonAttrib(pid, "武学常识", JY.Thing[thingid]["加武学常识"])
			AddPersonAttrib(pid, "品德", JY.Thing[thingid]["加品德"])
			AddPersonAttrib(pid, "攻击带毒", JY.Thing[thingid]["加攻击带毒"])
			if JY.Thing[thingid]["加攻击次数"] == 1 then
			  p["左右互搏"] = 1
			end
			p["修炼点数"] = p["修炼点数"] - needpoint

			if wugongid >= 0 then
				yes2 = true
				local oldwugong = 0
				for i = 1, CC.Kungfunum do
					if p["武功" .. i] == wugongid then
						oldwugong = 1
						p["武功等级" .. i] = math.modf((p["武功等级" .. i] + 100) / 100) * 100
						kfnum = i
						break;
					end
				end
				if oldwugong == 0 then
					for i = 1, CC.Kungfunum do
						if p["武功" .. i] == 0 then
							p["武功" .. i] = wugongid
							p["武功等级" .. i] = 0;
							kfnum = i
							break;
						end
					end
				end
			end
		else
			break;
		end
	end
	if yes1 then
		DrawStrBoxWaitKey(string.format("%s 修炼 %s 成功", p["姓名"], JY.Thing[thingid]["名称"]), C_WHITE, CC.DefaultFont)
	end
	if yes2 then
		--无酒不欢：自动到极的判定在这里
		if p["武功等级" .. kfnum] == 900 then
			--胡斐等人优先判定
			if (match_ID(pid, 1) and wugongid == 67) or (match_ID(pid, 37) and wugongid == 94) or (match_ID(pid, 38) and wugongid == 102) or (match_ID(pid, 49) and wugongid == 14) then
				DrawStrBoxWaitKey(string.format("%s 升为第%s级", JY.Wugong[wugongid]["名称"], math.modf(p["武功等级" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
			--内功和轻功
			elseif JY.Wugong[wugongid]["武功类型"] == 6 or JY.Wugong[wugongid]["武功类型"] == 7 then
				--三大吸功直接到极
				if wugongid == 85 or wugongid == 87 or wugongid == 88 then
					p["武功等级" .. kfnum] = 999
					DrawStrBoxWaitKey(string.format("%s 已修炼到极", JY.Wugong[wugongid]["名称"]), C_WHITE, CC.DefaultFont)
				--天内天轻可以到极
				elseif wugongid == p["天赋内功"] or wugongid == p["天赋轻功"] then
					p["武功等级" .. kfnum] = 999
					DrawStrBoxWaitKey(string.format("%s 已修炼到极", JY.Wugong[wugongid]["名称"]), C_WHITE, CC.DefaultFont)
				else
					DrawStrBoxWaitKey(string.format("%s 升为第%s级", JY.Wugong[wugongid]["名称"], math.modf(p["武功等级" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
				end
			--外功直接到极
			else
				p["武功等级" .. kfnum] = 999
				DrawStrBoxWaitKey(string.format("%s 已修炼到极", JY.Wugong[wugongid]["名称"]), C_WHITE, CC.DefaultFont)
			end
		else
			DrawStrBoxWaitKey(string.format("%s 升为第%s级", JY.Wugong[wugongid]["名称"], math.modf(p["武功等级" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
		end
	end
end

--特色指令
function War_TgrtsMenu()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	Cls()
	WAR.ShowHead = 0
	WarDrawMap(0)
	local grts_id;
	--如果是畅想
	if pid == 0 then
		grts_id = JY.Base["畅想"]
	else
		grts_id = pid
	end

	--郭襄的指令特殊
	if match_ID(pid, 626) then
		local wg = JYMsgBox("特色指令：" .. GRTS[grts_id], GRTSSAY[grts_id], {"弹指", "玉萧", "落英"}, 3, WAR.tmp[5000+WAR.CurID],1)
		if wg == 1 then
			JY.Person[pid]["武功1"] = 18
		elseif wg == 2 then
			JY.Person[pid]["武功1"] = 38
		elseif wg == 3 then
			JY.Person[pid]["武功1"] = 12
		end
		return 0
	else
		local yn = JYMsgBox("特色指令：" .. GRTS[grts_id], GRTSSAY[grts_id], {"确定", "取消"}, 2, WAR.tmp[5000+WAR.CurID])
		if yn == 2 then
			return 0
		end
	end

	--段誉
	if match_ID(pid, 53) then
		if JY.Person[pid]["体力"] > 20 then
			WAR.TZ_DY = 1
			PlayWavE(16)
			CurIDTXDH(WAR.CurID, 72,1, "休迅飞凫 飘忽若神", M_DeepSkyBlue, 15);
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--虚竹
	if match_ID(pid, 49) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
		  JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 5
		  JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
		  local ssh = {}
		  local num = 1
		  for i = 0, WAR.PersonNum - 1 do
			local wid = WAR.Person[i]["人物编号"]
			if WAR.TZ_XZ_SSH[wid] == 1 and WAR.Person[i]["死亡"] == false then
				--封穴25点
				if WAR.FXDS[wid] == nil then
					WAR.FXDS[wid] = 25
				else
					WAR.FXDS[wid] = WAR.FXDS[wid] + 25
				end
				if WAR.FXDS[wid] > 50 then
					WAR.FXDS[wid] = 50
				end
				WAR.TZ_XZ_SSH[wid] = nil
				if WAR.Person[i].Time > 995 then
					WAR.Person[i].Time = 995
				end
				ssh[num] = {}
				ssh[num][1] = i
				ssh[num][2] = wid
				num = num + 1
			end
		  end
		  local name = {}
		  for i = 1, num - 1 do
			name[i] = {}
			name[i][1] = JY.Person[ssh[i][2]]["姓名"]
			name[i][2] = nil
			name[i][3] = 1
		  end
		  DrawStrBox(CC.MainMenuX, CC.MainMenuY, "催符：", C_GOLD, CC.DefaultFont)
		  ShowMenu(name, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
		  Cls()
		  PlayWavAtk(32)
		  CurIDTXDH(WAR.CurID, 72,1, "符掌生死 德折群雄")
		  PlayWavE(8)
		  local sssid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)
		  for DH = 114, 129 do
			for i = 1, num - 1 do
			  local x0 = WAR.Person[WAR.CurID]["坐标X"]
			  local y0 = WAR.Person[WAR.CurID]["坐标Y"]
			  local dx = WAR.Person[ssh[i][1]]["坐标X"] - x0
			  local dy = WAR.Person[ssh[i][1]]["坐标Y"] - y0
			  local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			  local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
			  local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

			  ry = ry - hb
			  lib.PicLoadCache(3, DH * 2, rx, ry, 2, 192)
			  if DH > 124 then
				DrawString(rx - 10, ry - 15, "封穴", C_GOLD, CC.DefaultFont)
			  end
			end
			lib.ShowSurface(0)
			lib.LoadSur(sssid, 0, 0)
			lib.Delay(30)
		  end
		  lib.FreeSur(sssid)
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

  --人厨子
  if match_ID(pid, 89) then
    if JY.Person[pid]["体力"] > 25 and JY.Person[pid]["内力"] > 300 then
      local px, py = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
      local mxy = {
					{WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] + 1},
					{WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] - 1},
					{WAR.Person[WAR.CurID]["坐标X"] + 1, WAR.Person[WAR.CurID]["坐标Y"]},
					{WAR.Person[WAR.CurID]["坐标X"] - 1, WAR.Person[WAR.CurID]["坐标Y"]}}
      local zdp = {}
      local num = 1
      for i = 1, 4 do
        if GetWarMap(mxy[i][1], mxy[i][2], 2) >= 0 then
          local mid = GetWarMap(mxy[i][1], mxy[i][2], 2)
          if inteam(WAR.Person[mid]["人物编号"]) then
          	zdp[num] = WAR.Person[mid]["人物编号"]
          	num = num + 1
        	end
        end

      end
      local zdp2 = {}
      for i = 1, num - 1 do
        zdp2[i] = {}
        zdp2[i][1] = JY.Person[zdp[i]]["姓名"] .. "·" .. JY.Person[zdp[i]]["体力"]
        zdp2[i][2] = nil
        zdp2[i][3] = 1
      end
      DrawStrBox(CC.MainMenuX, CC.MainMenuY, "气补：", C_GOLD, CC.DefaultFont)
      local r = ShowMenu(zdp2, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
      Cls()
      AddPersonAttrib(zdp[r], "体力", 50)
      AddPersonAttrib(pid, "体力", -25)
      AddPersonAttrib(pid, "内力", -300)
      PlayWavE(28)
      lib.Delay(10)
      CurIDTXDH(WAR.CurID, 86,1, "化气补元")
      local Ocur = WAR.CurID
      for i = 0, WAR.PersonNum - 1 do
        if WAR.Person[i]["人物编号"] == zdp[r] then
          WAR.CurID = i
        end
      end
      WarDrawMap(0)
      PlayWavE(36)
      lib.Delay(100)
      CurIDTXDH(WAR.CurID, 86, 1, "恢复体力50点")
      WAR.CurID = Ocur
      WarDrawMap(0)
    else
    	DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
    	return 0
    end
  end

  --张无忌
  if match_ID(pid, 9) then
    if JY.Person[pid]["体力"] > 10 and JY.Person[pid]["内力"] > 500 then
      local nyp = {}
      local num = 1
      for i = 0, WAR.PersonNum - 1 do
        if WAR.Person[i]["我方"] == true and WAR.Person[i]["死亡"] == false and RealJL(WAR.CurID, i, 8) and i ~= WAR.CurID then
          nyp[num] = {}
          nyp[num][1] = JY.Person[WAR.Person[i]["人物编号"]]["姓名"]
          nyp[num][2] = nil
          nyp[num][3] = 1
          nyp[num][4] = i
          num = num + 1
        end
      end
      DrawStrBox(CC.MainMenuX, CC.MainMenuY, "挪移：", C_GOLD, CC.DefaultFont)
      local r = ShowMenu(nyp, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
      Cls()
      local mid = WAR.Person[nyp[r][4]]["人物编号"]
      QZXS("请选择要将" .. JY.Person[mid]["姓名"] .. "挪移到什么位置？")
      War_CalMoveStep(WAR.CurID, 8, 1)
      local nx, ny = nil, nil
      while true do
	      nx, ny = War_SelectMove()
	      if nx ~= nil then
		      if lib.GetWarMap(nx, ny, 2) > 0 or lib.GetWarMap(nx, ny, 5) > 0 then
		        QZXS("此处有人！请重新选择")			--此处有人！请重新选择
	      	elseif CC.SceneWater[lib.GetWarMap(nx, ny, 0)] ~= nil then
	        	QZXS("水面，不可进入！请重新选择")		--水面，不可进入！请重新选择
	       	else
	       		break;
	        end
	      end
	    end
	    PlayWavE(5)
	    CurIDTXDH(WAR.CurID, 88,1, "九阳明尊 挪移乾坤")		--九阳明尊 挪移乾坤
	    local Ocur = WAR.CurID
	    WAR.CurID = nyp[r][4]
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] = nx, ny
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
	    lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    WAR.CurID = Ocur
	    AddPersonAttrib(pid, "体力", -10)
	    AddPersonAttrib(pid, "内力", -500)

	  else
	  	DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
	  	return 0
	  end
	end

	--祖千秋
	if match_ID(pid, 88) then
	  if JY.Person[pid]["体力"] > 10 and JY.Person[pid]["内力"] > 700 then
	    local dxp = {}
	    local num = 1
	    for i = 0, WAR.PersonNum - 1 do
	      if WAR.Person[i]["我方"] == true and WAR.Person[i]["死亡"] == false and RealJL(WAR.CurID, i, 5) and i ~= WAR.CurID then
	        dxp[num] = {}
	        dxp[num][1] = JY.Person[WAR.Person[i]["人物编号"]]["姓名"]
	        dxp[num][2] = nil
	        dxp[num][3] = 1
	        dxp[num][4] = i
	        num = num + 1
	      end
	    end
	    DrawStrBox(CC.MainMenuX, CC.MainMenuY, "传功：", C_GOLD, 30)
	    local r = ShowMenu(dxp, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
	    Cls()
	    local mid = WAR.Person[dxp[r][4]]["人物编号"]
	    PlayWavE(28)
	    lib.Delay(10)
	    CurIDTXDH(WAR.CurID,87,1, "酒神戏红尘")
	    local Ocur = WAR.CurID
	    WAR.CurID = dxp[r][4]
	    WarDrawMap(0)
	    PlayWavE(36)
	    lib.Delay(100)
	    CurIDTXDH(WAR.CurID, 87, 1, "集气上升500")
	    WAR.CurID = Ocur
	    WarDrawMap(0)
	    WAR.Person[dxp[r][4]].Time = WAR.Person[dxp[r][4]].Time + 500
	    if WAR.Person[dxp[r][4]].Time > 999 then
	      WAR.Person[dxp[r][4]].Time = 999
	    end
	    AddPersonAttrib(pid, "体力", -10)
	    AddPersonAttrib(pid, "内力", -1000)
	  else
	  	DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
	  	return 0
		end
	end

	--蓝烟清：霍青桐统率指令，我方全体集气值加200点
	if match_ID(pid, 74) then
		if JY.Person[pid]["体力"] > 10 and JY.Person[pid]["内力"] > 150 then
			CurIDTXDH(WAR.CurID, 92,1, "统率");		--动画显示
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["我方"] == true and WAR.Person[i]["死亡"] == false and i ~= WAR.CurID then
					WAR.Person[i].Time = WAR.Person[i].Time + 200;
					if WAR.Person[i].Time > 999 then
						WAR.Person[i].Time = 999;
					end
				end
			end
			AddPersonAttrib(pid, "体力", -10)
			AddPersonAttrib(pid, "内力", -150)
			lib.Delay(100)
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
	  	return 0
		end
	end

	--萧中慧，慧心
	if match_ID(pid, 77) then
		if JY.Person[pid]["生命"] > 500 and JY.Person[pid]["受伤程度"] < 50 then
			local zjwid = nil
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["人物编号"] == 0 and WAR.Person[i]["死亡"] == false then
					zjwid = i
					break
				end
			end
			if zjwid ~= nil then
				DrawStrBoxWaitKey("我心本慧·侠女柔情", C_RED, 36)
				say("２慧妹……！",0,1)
				if JY.Person[0]["性别"] == 0 then
					say("１ｎ哥哥，９请…………２加油！",77,0)
				else
					say("１ｎ姐姐，９请…………２加油！",77,0)
				end
				JY.Person[pid]["生命"] = 1
				JY.Person[pid]["受伤程度"] = 100
				WAR.Person[WAR.CurID].Time = -500
				JY.Person[0]["生命"] = JY.Person[0]["生命最大值"]
				JY.Person[0]["受伤程度"] = 0
				WAR.Person[zjwid].Time = 999
				WAR.FXDS[0] = nil
				WAR.LQZ[0] = 100
			else
				DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)		-- "未满足发动条件"
				return 0
			end

		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)		-- "未满足发动条件"
			return 0
		end
	end

	--蓝烟清：王难姑特色指令 - 施毒  周围五格范围内的敌人时序中毒并时序减血
	if match_ID(pid, 17) then
		if JY.Person[pid]["体力"] >= 30 and JY.Person[pid]["内力"] >= 300 then
			CleanWarMap(4,0);
			AddPersonAttrib(pid, "体力", -15)
			AddPersonAttrib(pid, "内力", -300)
			local x1 = WAR.Person[WAR.CurID]["坐标X"];
			local y1 = WAR.Person[WAR.CurID]["坐标Y"];
			for ex = x1 - 5, x1 + 5 do
				for ey = y1 - 5, y1 + 5 do
					SetWarMap(ex, ey, 4, 1)
					if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
						local ep = GetWarMap(ex, ey, 2)
						if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[ep]["我方"] then

							WAR.L_WNGZL[WAR.Person[ep]["人物编号"]] = 50;			--50时序内持续减中毒+减血
							SetWarMap(ex, ey, 4, 4)
						end
					end
				end
			end
			War_ShowFight(pid,0,0,0,x1,y1,30);
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--brolycjw：胡青牛特色指令 - 群疗  周围五格范围内的队友时序回内伤并按比例回血
	if match_ID(pid, 16) then
		if JY.Person[pid]["体力"] >= 30 and JY.Person[pid]["内力"] >= 300 then
			CleanWarMap(4,0);
			AddPersonAttrib(pid, "体力", -15)
			AddPersonAttrib(pid, "内力", -300)
			local x1 = WAR.Person[WAR.CurID]["坐标X"];
			local y1 = WAR.Person[WAR.CurID]["坐标Y"];

			for ex = x1 - 5, x1 + 5 do
				for ey = y1 - 5, y1 + 5 do
					SetWarMap(ex, ey, 4, 1)
					if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
						local ep = GetWarMap(ex, ey, 2)
						if WAR.Person[WAR.CurID]["我方"] == WAR.Person[ep]["我方"] then

							WAR.L_HQNZL[WAR.Person[ep]["人物编号"]] = 20;			--20时序内持续回血+回内伤
							SetWarMap(ex, ey, 4, 4)

						end
					end
				end
			end
			War_ShowFight(pid,0,0,0,x1,y1,0);

		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--慕容复 幻梦
	if match_ID(pid, 51) then
		if JY.Person[pid]["体力"] > 20 then
			WAR.TZ_MRF = 1
			CurIDTXDH(WAR.CurID, 127,1, "顾盼子孙贤 铭记复国志", C_GOLD);
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--小昭 影步
	if match_ID(pid, 66) then
		if JY.Person[pid]["体力"] > 30 and JY.Person[pid]["内力"] > 2000 then
			War_CalMoveStep(WAR.CurID, 10, 0)
			WAR.XZ_YB[1],WAR.XZ_YB[2]=War_SelectMove()
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 20
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 1000
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--钟灵指令 灵貂
	if match_ID(pid, 90) then
		if JY.Person[pid]["体力"] > 10 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["我方"] == WAR.Person[WAR.CurID]["我方"] then
					return 0
				end
				local eid = WAR.Person[tdID]["人物编号"]
				local x0, y0 = WAR.Person[WAR.CurID]["坐标X"],WAR.Person[WAR.CurID]["坐标Y"]
				local x1, y1 = WAR.Person[tdID]["坐标X"],WAR.Person[tdID]["坐标Y"]
				for i = 1, 4 do
					if 0 < JY.Person[eid]["携带物品数量" .. i] and -1 < JY.Person[eid]["携带物品" .. i] then
						WAR.TD = JY.Person[eid]["携带物品" .. i]
						WAR.TDnum = JY.Person[eid]["携带物品数量" .. i]
						JY.Person[eid]["携带物品数量" .. i] = 0
						JY.Person[eid]["携带物品" .. i] = -1
						break
					end
				end
				WAR.Person[WAR.CurID]["人方向"] = War_Direct(x0, y0, x1, y1)
				CleanWarMap(4, 0)
				SetWarMap(x1, y1, 4, 1)
				WAR.Person[tdID]["中毒点数"] = (WAR.Person[tdID]["中毒点数"] or 0) + AddPersonAttrib(eid, "中毒程度", 50)
				WAR.TXXS[eid] = 1
				War_ShowFight(WAR.Person[WAR.CurID]["人物编号"], 0, 0, 0, 0, 0, 12)
				if WAR.TD ~= -1 then
					if WAR.TD == 118 then
						say("１想要从我慕容复手中偷东西？哼哼，下辈子吧！", 51,0)
					else
						instruct_2(WAR.TD, WAR.TDnum)
					end
					WAR.TD = -1
					WAR.TDnum = 0
				end
				WAR.TXXS[eid] = nil
			else
				return 0
			end
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 5
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--胡斐 飞狐
	if match_ID(pid, 1) then
		if JY.Person[pid]["体力"] > 20 then
			War_CalMoveStep(WAR.CurID, 10, 2)
			local x,y = War_SelectMove()
			if not x then
				return 0
			end
			if GetWarMap(x, y, 1) > 0 or GetWarMap(x, y, 2) > 0 or GetWarMap(x, y, 5) > 0 or CC.WarWater[GetWarMap(x, y, 0)] ~= nil then
				return 0
			else
				CurIDTXDH(WAR.CurID, 25,1, "雪山飞狐", Violet);
				WAR.Person[WAR.CurID]["移动步数"] = 10
				War_MovePerson(x, y, 1)
				WAR.Person[WAR.CurID]["移动步数"] = 0
				JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			end
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--鸠摩智 幻化
	if match_ID(pid, 103) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			local thing = {}
			local thingnum = {}
			for i = 0, CC.MyThingNum - 1 do
				thing[i] = -1
				thingnum[i] = 0
			end
			local num = 0
			for i = 0, CC.MyThingNum - 1 do
				local id = JY.Base["物品" .. i + 1]
				if id >= 0 then
					if JY.Thing[id]["类型"] == 2 and JY.Thing[id]["练出武功"] > -1 then
						thing[num] = id
						thingnum[num] = JY.Base["物品数量" .. i + 1]
						num = num + 1
					end
				end
			end
			IsViewingKungfuScrolls = 1
			local r = SelectThing(thing, thingnum)
			if r >= 0 then
				CurIDTXDH(WAR.CurID, 93,1, "无相幻化", C_GOLD)
				JY.Person[pid]["武功2"]= JY.Thing[r]["练出武功"]
				JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
				JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--达尔巴指令 死战
	if match_ID(pid, 160) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["我方"] == WAR.Person[WAR.CurID]["我方"] then
					return 0
				end
				local eid = WAR.Person[tdID]["人物编号"]
				WAR.SZSD = eid

				CurIDTXDH(WAR.CurID, 93,1, "锁定目标", C_GOLD)
				JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
				JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--金轮 龙象
	if match_ID(pid, 62) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			War_ActupMenu()
			WAR.SLSX[pid] = 2
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--黄蓉 遁甲
	if match_ID(pid, 56) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			local x,y = WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"]
			--1绿色，2红色，3蓝色，4紫色
			CleanWarMap(6,-1);

			local QMDJ = {"休","生","伤","杜","景","死","惊","开"}

			--在自身周围绘制奇阵
			SetWarMap(x,y, 6, math.random(4))

			for j=1, 2 do
				SetWarMap(x + math.random(6), y + math.random(6), 6, math.random(4));
				for i = 30, 40 do
					NewDrawString(-1, -1, QMDJ[j], C_GOLD, CC.DefaultFont+i*2)
					ShowScreen()
					if i == 40 then
						lib.Delay(300)
						Cls()
					else
						lib.Delay(1)
					end
				end
			end

			for j=3, 4 do
				SetWarMap(x + math.random(6), y - math.random(6), 6, math.random(4));
				for i = 30, 40 do
					NewDrawString(-1, -1, QMDJ[j], C_GOLD, CC.DefaultFont+i*2)
					ShowScreen()
					if i == 40 then
						lib.Delay(300)
						Cls()
					else
						lib.Delay(1)
					end
				end
			end

			for j=5, 6 do
				SetWarMap(x - math.random(6), y - math.random(6), 6, math.random(4));
				for i = 30, 40 do
					NewDrawString(-1, -1, QMDJ[j], C_GOLD, CC.DefaultFont+i*2)
					ShowScreen()
					if i == 40 then
						lib.Delay(300)
						Cls()
					else
						lib.Delay(1)
					end
				end
			end

			for j=7, 8 do
				SetWarMap(x - math.random(6), y + math.random(6), 6, math.random(4));
				for i = 30, 40 do
					NewDrawString(-1, -1, QMDJ[j], C_GOLD, CC.DefaultFont+i*2)
					ShowScreen()
					if i == 40 then
						lib.Delay(300)
						Cls()
					else
						lib.Delay(1)
					end
				end
			end
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--阿紫，禁药
	if match_ID(pid, 47) then
		WAR.JYZT[pid] = 1
		CurIDTXDH(WAR.CurID, 128,1, "禁药", C_RED);
		return 20
	end

	--韦小宝 口才
	if match_ID(pid, 601) then
		if JY.Person[pid]["体力"] > 30 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["我方"] == WAR.Person[WAR.CurID]["我方"] then
					return 0
				end
				local eid = WAR.Person[tdID]["人物编号"]
				WAR.CSZT[eid] = 1

				Cls()
				local KC = {"阁下英明神武","鸟生鱼汤"}

				for i = 1, #KC do
					lib.GetKey()
					DrawString(-1, -1, KC[i], C_GOLD, CC.Fontsmall)
					ShowScreen()
					Cls()
					lib.Delay(1000)
				end
				local s = WAR.CurID
				WAR.CurID = tdID
				WarDrawMap(0)
				CurIDTXDH(WAR.CurID, 145,1)
				WAR.CurID = s
				JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 15
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--苗人凤指令 破军
	if match_ID(pid, 3) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			WAR.MRF = 1
			if War_FightMenu() == 0 then
				return 0
			end
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 300
			WAR.MRF = 0
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--灭绝，俱焚
	if match_ID(pid, 6) then
		WAR.YSJF[pid] = 100
		CurIDTXDH(WAR.CurID, 124,1, "玉石俱焚", M_Silver);
		return 20
	end

	--谢逊指令 咆哮
	if match_ID(pid, 13) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 3000 then
			CurIDTXDH(WAR.CurID, 118,1, "狮王咆哮", C_GOLD)
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[j]["死亡"] == false then
					WAR.HLZT[WAR.Person[j]["人物编号"]] = 20
				end
			end
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 2000
			WAR.MRF = 0
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--何太冲指令 琴音
	if match_ID(pid, 7) then
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			CleanWarMap(4, 0)
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
					local eid = WAR.Person[j]["人物编号"]
					local qycs = WAR.QYZT[eid] or 0
					if qycs > 0 then
						WAR.TXXS[eid] = 1
						--无酒不欢：记录人物血量
						WAR.Person[j]["Life_Before_Hit"] = JY.Person[eid]["生命"]
						JY.Person[eid]["生命"] = JY.Person[eid]["生命"] - 50*qycs
						WAR.Person[j]["生命点数"] = (WAR.Person[j]["生命点数"] or 0) - 50*qycs
						SetWarMap(WAR.Person[j]["坐标X"], WAR.Person[j]["坐标Y"], 4, 1)
						WAR.QYZT[eid] = nil
					end
				end
			end
			War_ShowFight(WAR.Person[WAR.CurID]["人物编号"], 0, 0, 0, 0, 0, 144)
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--阎基指令 虚弱
	if match_ID(pid, 4) then
		if JY.Person[pid]["体力"] > 20 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["我方"] == WAR.Person[WAR.CurID]["我方"] then
					return 0
				end
				local eid = WAR.Person[tdID]["人物编号"]
				local x0, y0 = WAR.Person[WAR.CurID]["坐标X"],WAR.Person[WAR.CurID]["坐标Y"]
				local x1, y1 = WAR.Person[tdID]["坐标X"],WAR.Person[tdID]["坐标Y"]

				WAR.XRZT[eid] = 30
				WAR.Person[WAR.CurID]["人方向"] = War_Direct(x0, y0, x1, y1)
				CleanWarMap(4, 0)
				SetWarMap(x1, y1, 4, 1)
				War_ShowFight(WAR.Person[WAR.CurID]["人物编号"], 0, 0, 0, 0, 0, 148)
			else
				return 0
			end
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--黛绮丝，倾国
	if match_ID(pid, 15) then
		WAR.QGZT[pid] = 6
		CurIDTXDH(WAR.CurID, 149,1)
		JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
	end

	--喵姐指令 女装
	if match_ID(pid, 92) then
		if JY.Person[pid]["体力"] > 20 then
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "日出东方 唯喵姐不败", C_GOLD)
			lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
			lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
			WarDrawMap(0)
			local mj = {}
			if JY.Person[pid]["性别"] == 0 then
				JY.Person[pid]["头像代号"] = 384
				JY.Person[pid]["性别"] = 1
				JY.Person[pid]["武功2"] = 154
				JY.Person[pid]["天赋内功"] = 154
				JY.Person[pid]["主运内功"] = 154
				mj[1]={0,15,0,0,0}
				mj[2]={0,13,0,0,0}
				mj[3]={0,13,0,0,0}
			else
				JY.Person[pid]["头像代号"] = 387
				JY.Person[pid]["性别"] = 0
				JY.Person[pid]["武功2"] = 105
				JY.Person[pid]["天赋内功"] = 105
				JY.Person[pid]["主运内功"] = 105
				mj[1]={0,14,0,0,0}
				mj[2]={0,12,0,0,0}
				mj[3]={0,12,0,0,0}
			end
			for i = 1, 5 do
				JY.Person[pid]["出招动画帧数" .. i] = mj[1][i]
				JY.Person[pid]["出招动画延迟" .. i] = mj[2][i]
				JY.Person[pid]["武功音效延迟" .. i] = mj[3][i]
			end
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["人物编号"] == 92 then
					lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[pid]["头像代号"]), string.format(CC.FightPicFile[2], JY.Person[pid]["头像代号"]), 4 + i)
					WAR.tmp[5000+i] = JY.Person[pid]["头像代号"]
					break
				end
			end
			WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "日出东方 唯喵姐不败", C_GOLD)
			lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
			lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "日出东方 唯喵姐不败", C_GOLD)
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--方证 金身
	if match_ID(pid, 149) then
		if WAR.JSBM[pid] ~= nil then
			WAR.JSBM[pid] = nil
			return 20
		end
		if JY.Person[pid]["体力"] > 20 and JY.Person[pid]["内力"] > 1000 then
			WAR.JSBM[pid] = 1
			CurIDTXDH(WAR.CurID, 78,1,"金身不灭",C_GOLD)
			JY.Person[pid]["体力"] = JY.Person[pid]["体力"] - 10
			JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - 500
			return 20
		else
			DrawStrBoxWaitKey("未满足发动条件", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	return 1
end

--战斗蓄力
function War_ActupMenu()
	local p = WAR.CurID
	local id = WAR.Person[p]["人物编号"]
	local x0, y0 = WAR.Person[p]["坐标X"], WAR.Person[p]["坐标Y"]

	--赵敏是否在场
	local ZM = 0
	if inteam(id) then
		for i = 0, WAR.PersonNum - 1 do
			local zid = WAR.Person[i]["人物编号"]
			if WAR.Person[i]["死亡"] == false and WAR.Person[i]["我方"] == false then
				JY.Person[zid]["生命"] = 0
			end
		end
	end

	--主运蛤蟆蓄力带防御效果
	if Curr_NG(id, 95) then
		WAR.Actup[id] = 2;
		WAR.Defup[id] = 1
		WAR.HMGXL[id] = 1
		CurIDTXDH(WAR.CurID, 85,1);
		DrawStrBox(-1, -1, "攻守兼备·蓄势待发", LightSlateBlue, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--被动紫霞蓄力强化
	elseif PersonKF(id, 89) then
		WAR.Actup[id] = 2
		if inteam(id) then
			WAR.ZXXS[id] = 1 + math.modf(JY.Base["天书数量"]/7)
		else
			WAR.ZXXS[id] = 3
		end
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "紫霞蓄势·连绵不绝", Violet, CC.DefaultFont, M_DeepSkyBlue)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--被动龙象蓄力带防御效果
	elseif PersonKF(id, 103) then
		WAR.Actup[id] = 2;
		WAR.Defup[id] = 1
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "龙之蓄力·象之防御", LightGreen, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--标主蓄力必成功
	elseif id == 0 and JY.Base["标准"] > 0 then
		WAR.Actup[id] = 2
	--NPC蓄力必成功
	elseif not inteam(id) then
		WAR.Actup[id] = 2
	--我方，赵敏在场必成功
	elseif inteam(id) and ZM == 1 then
		WAR.Actup[id] = 2
	--常态70%几率成功
	elseif JLSD(15, 85, id) then
		WAR.Actup[id] = 2
	end
	if WAR.Actup[id] ~= 2 then
		Cls()
		DrawStrBox(-1, -1, "蓄力失败", C_GOLD, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
	else
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "蓄力成功", C_GOLD, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
	end
	return 1
end


--战斗防御
function War_DefupMenu()
	local p = WAR.CurID
	local id = WAR.Person[p]["人物编号"]
	local x0, y0 = WAR.Person[p]["坐标X"], WAR.Person[p]["坐标Y"]
	WAR.Defup[id] = 1
	Cls()
	local hb = GetS(JY.SubScene, x0, y0, 4)

	--太玄防御带蓄力
	if PersonKF(id, 102) then
		WAR.Actup[id] = 2;
		CurIDTXDH(WAR.CurID, 86,1);
		DrawStrBox(-1, -1, "防御开始·太玄蓄力", C_RED, CC.DefaultFont, C_GOLD)
		ShowScreen()
		lib.Delay(400)
		return 1;
	end

	CurIDTXDH(WAR.CurID, 86,1);
	DrawStrBox(-1, -1, "防御开始", LimeGreen, CC.DefaultFont, C_GOLD)
	ShowScreen()
	lib.Delay(400)
	return 1
end

--设置人物的集气值，返回一个综合值以便循环刷新集气条
function GetJiqi()
	local num, total = 0, 0
	for i = 0, WAR.PersonNum - 1 do
		if not WAR.Person[i]["死亡"] then
			local id = WAR.Person[i]["人物编号"]
			WAR.Person[i].TimeAdd = 20

			num = num + 1
			total = total + WAR.Person[i].TimeAdd
		end
	end

	--无酒不欢：这个返回值表达不明确，存疑
	WAR.LifeNum = num
	return math.modf(((total) / (num) + (num) - 2))
end


--武功范围选择
function War_KfMove(movefanwei, atkfanwei, wugong)
  local kind = movefanwei[1] or 0
  local len = movefanwei[2] or 0
  local negativelen = movefanwei[3] or 0
  local x0 = WAR.Person[WAR.CurID]["坐标X"]
  local y0 = WAR.Person[WAR.CurID]["坐标Y"]
  local x = x0
  local y = y0
  if kind ~= nil then
    if kind == 0 then
      War_CalMoveStep(WAR.CurID, len, 1)
	elseif kind == 1 then
	    War_CalMoveStep(WAR.CurID, len * 2, 1)
	    for r = 1, len * 2 do
	      for i = 0, r do
	        local j = r - i
	        if len < i or len < j then
	          SetWarMap(x0 + i, y0 + j, 3, 255)
	          SetWarMap(x0 + i, y0 - j, 3, 255)
	          SetWarMap(x0 - i, y0 + j, 3, 255)
	          SetWarMap(x0 - i, y0 - j, 3, 255)
	        end
	      end
	    end
	elseif kind == 2 then
	    War_CalMoveStep(WAR.CurID, len, 1)
	    for i = 1, len - 1 do
	      for j = 1, len - 1 do
	        SetWarMap(x0 + i, y0 + j, 3, 255)
	        SetWarMap(x0 - i, y0 + j, 3, 255)
	        SetWarMap(x0 + i, y0 - j, 3, 255)
	        SetWarMap(x0 - i, y0 - j, 3, 255)
	      end
	    end
	elseif kind == 3 then
	    War_CalMoveStep(WAR.CurID, 2, 1)
	    SetWarMap(x0 + 2, y0, 3, 255)
	    SetWarMap(x0 - 2, y0, 3, 255)
	    SetWarMap(x0, y0 + 2, 3, 255)
	    SetWarMap(x0, y0 - 2, 3, 255)
	  else
	    War_CalMoveStep(WAR.CurID, 0, 1)
	  end
  end

  CleanWarMap(7, 0)

  while true do
	if JY.Restart == 1 then
		break
	end
    local x2 = x
    local y2 = y

	WarDrawMap(1, x, y)
    WarDrawAtt(x, y, atkfanwei, 4)

	--判断合击，判断是否有合击者

	local ZHEN_ID = -1;
    
	WarDrawMap(1, x, y)
    WarShowHead(GetWarMap(x, y, 2))
	
	--合击人标识
	if ZHEN_ID ~= -1 then
		local nx = WAR.Person[ZHEN_ID]["坐标X"]
		local ny = WAR.Person[ZHEN_ID]["坐标Y"]
		local dx = nx - x0
		local dy = ny - y0
		local size = CC.FontSmall;
		local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
		local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
									
		local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
									
		DrawString(rx - size*1.5, ry-hb-size/2, "合击者", M_DeepSkyBlue, size);
	end

	--显示可以覆盖的敌人信息
	for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			local target = GetWarMap(i, j, 7)
			if target ~= nil and target == 2 then
				if GetWarMap(i, j, 2) ~= nil and WAR.Person[GetWarMap(i, j, 2)]["人物编号"] ~= nil then
					local x0 = WAR.Person[WAR.CurID]["坐标X"];
					local y0 = WAR.Person[WAR.CurID]["坐标Y"];
					local dx = i - x0
					local dy = j - y0
					local size = CC.FontSmall;
					local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
					local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

					local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

					ry = ry - hb - CC.ScreenH/6;

					if ry < 1 then			--加上这个，防止看不到血的情况
						ry = 1;
					end

					--显示选中人物的生命值
					local color = RGB(245, 251, 5);
					local hp = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["人物编号"]]["生命"] or 0;
					local maxhp = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["人物编号"]]["生命最大值"] or 0;

					local ns = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["人物编号"]]["受伤程度"] or 0;
					local zd = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["人物编号"]]["中毒程度"] or 0;
					local len = #(string.format("%d/%d",hp,maxhp));
					rx = rx - len*size/4;

					--颜色根据所受的内伤确定
					if ns < 33 then
						color = RGB(236, 200, 40)
					elseif ns < 66 then
						color = RGB(244, 128, 32)
					else
						color = RGB(232, 32, 44)
					end

					DrawString(rx, ry, string.format("%d",hp), color, size);
					DrawString(rx + #string.format("%d",hp)*size/2, ry, "/", C_GOLD, size);

					if zd == 0 then
						color = RGB(252, 148, 16)
					elseif zd < 50 then
						color = RGB(120, 208, 88)
					else
						color = RGB(56, 136, 36)
					end
					DrawString(rx + #string.format("%d",hp)*size/2 + size/2 , ry, string.format("%d", maxhp), color, size)
				end
			end
		end
	end

    ShowScreen()
	CleanWarMap(7, 0)

    local key, ktype, mx, my = WaitKey(1)
	local movetime = 1
    if key == VK_UP then
      y2 = y - movetime
    elseif key == VK_DOWN then
      y2 = y + movetime
    elseif key == VK_LEFT then
      x2 = x - movetime
    elseif key == VK_RIGHT then
      x2 = x + movetime
    elseif (key == VK_SPACE or key == VK_RETURN) then
		if WAR.Person[GetWarMap(x, y, 2)] ~= nil and WAR.Person[GetWarMap(x, y, 2)]["我方"] == false then
			local distance = math.abs(x-x0) + math.abs(y-y0)
			if distance <= negativelen then
				DrawStrBoxWaitKey("该武功最小距离为"..(negativelen + 1), C_WHITE, CC.DefaultFont)
			else
				return x, y
			end
		else
			DrawStrBoxWaitKey("需指定敌人为目标", C_WHITE, CC.DefaultFont)
		end
    elseif key == VK_ESCAPE or ktype == 4 then
      return nil
    elseif ktype == 2 or ktype == 3 then
      mx = mx - CC.ScreenW / 2
      my = my - CC.ScreenH / 2
      mx = (mx) / CC.XScale
      my = (my) / CC.YScale
      mx, my = (mx + my) / 2, (my - mx) / 2
      if mx > 0 then
        mx = mx + 0.99
      else
        mx = mx - 0.01
      end
      if my > 0 then
        my = my + 0.99
      else
        mx = mx - 0.01
      end
      mx = math.modf(mx)
      my = math.modf(my)
      for i = 1, 20 do
        if mx + i > 63 or my + i > 63 then
           return;
        end
        local hb = GetS(JY.SubScene, mx + i, my + i, 4)

        if math.abs(hb - CC.YScale * i * 2) < 8 then
          mx = mx + i
          my = my + i
        end
      end

      x2, y2 = mx + x0, my + y0
	    if ktype == 3 and (kind < 2 or x ~= x0 or y ~= y0) then
	      	if WAR.Person[GetWarMap(x, y, 2)] ~= nil and WAR.Person[GetWarMap(x, y, 2)]["我方"] == false then
      			return x, y
			end
	    end

    end
    if x2 >= 0 and x2 < CC.WarWidth and y2 >= 0 and y2 < CC.WarHeight then
			if GetWarMap(x2, y2, 3) ~= nil and GetWarMap(x2, y2, 3) < 128 then
	      x = x2
	      y = y2
		  end
		end
	end
end
--WarDrawAtt 
function WarDrawAtt(x, y, fanwei, flag, cx, cy, atk)
  local x0, y0 = nil, nil
  if cx == nil or cy == nil then
    x0 = WAR.Person[WAR.CurID]["坐标X"]
    y0 = WAR.Person[WAR.CurID]["坐标Y"]
  else
    x0, y0 = cx, cy
  end
  local kind = fanwei[1]			--攻击范围
  local len1 = fanwei[2]
  local len2 = fanwei[3]
  local len3 = fanwei[4]
  local len4 = fanwei[5]
  local xy = {}
  local num = 0
  if kind == 0 then
    num = 1
    xy[1] = {x, y}
  elseif kind == 1 then
    if not len1 then
      len1 = 0
    end
    if not len2 then
      len2 = 0
    end
    num = num + 1
    xy[num] = {x, y}
    for i = 1, len1 do
      xy[num + 1] = {x + i, y}
      xy[num + 2] = {x - i, y}
      xy[num + 3] = {x, y + i}
      xy[num + 4] = {x, y - i}
      num = num + 4
    end
    for i = 1, len2 do
      xy[num + 1] = {x + i, y + i}
      xy[num + 2] = {x - i, y - i}
      xy[num + 3] = {x - i, y + i}
      xy[num + 4] = {x + i, y - i}
      num = num + 4
    end
  elseif kind == 2 then
    for tx = x - len1, x + len1 do
      for ty = y - len1, y + len1 do
        if len1 < math.abs(tx - x) + math.abs(ty - y) then

        else
        	num = num + 1
        	xy[num] = {tx, ty}
        end

      end
    end
  elseif kind == 3 then
    if not len2 then
      len2 = len1
    end
    local dx, dy = math.abs(x - x0), math.abs(y - y0)
    if dy < dx then
      len1, len2 = len2, len1
    end
    for tx = x - len1, x + len1 do
      for ty = y - len2, y + len2 do
        num = num + 1
        xy[num] = {tx, ty}
      end
    end
  elseif kind == 5 then
    if not len1 then
      len1 = 0
    end
    if not len2 then
      len2 = 0
    end
    num = num + 1
    xy[num] = {x, y}
    for i = 1, len1 do
      xy[num + 1] = {x + i, y}
      xy[num + 2] = {x - i, y}
      xy[num + 3] = {x, y + i}
      xy[num + 4] = {x, y - i}
      num = num + 4
    end
    if len2 > 0 then
      xy[num + 1] = {x + 1, y + 1}
      xy[num + 2] = {x + 1, y - 1}
      xy[num + 3] = {x - 1, y + 1}
      xy[num + 4] = {x - 1, y - 1}
      num = num + 4
    end
    for i = 2, len2 do
      xy[num + 1] = {x + i, y + 1}
      xy[num + 2] = {x - i, y - 1}
      xy[num + 3] = {x - i, y + 1}
      xy[num + 4] = {x + i, y - 1}
      xy[num + 5] = {x + 1, y + i}
      xy[num + 6] = {x - 1, y - i}
      xy[num + 7] = {x - 1, y + i}
      xy[num + 8] = {x + 1, y - i}
      num = num + 8
    end
  elseif kind == 6 then
    if not len2 then
      len2 = len1
    end
    xy[1] = {x + 1, y}
    xy[2] = {x - 1, y}
    xy[3] = {x, y + 1}
    xy[4] = {x, y - 1}
    num = num + 4
    if len1 > 0 or len2 > 0 then
      xy[5] = {x + 1, y + 1}
      xy[6] = {x + 1, y - 1}
      xy[7] = {x - 1, y + 1}
      xy[8] = {x - 1, y - 1}
      num = num + 4
      for i = 2, len1 do
        xy[num + 1] = {x + i, y + 1}
        xy[num + 2] = {x - i, y + 1}
        xy[num + 3] = {x + i, y - 1}
        xy[num + 4] = {x - i, y - 1}
        num = num + 4
      end
      for i = 2, len2 do
        xy[num + 1] = {x + 1, y + i}
        xy[num + 2] = {x + 1, y - i}
        xy[num + 3] = {x - 1, y + i}
        xy[num + 4] = {x - 1, y - i}
        num = num + 4
      end
    end
  elseif kind == 7 then
    if not len2 then
      len2 = len1
    end
    if len1 == 0 then
      for i = y - len2, y + len2 do
        num = num + 1
        xy[num] = {x, i}
      end
    elseif len2 == 0 then
      for i = x - len1, x + len1 do
        num = num + 1
        xy[num] = {i, y}
      end
    else
      for i = x - len1, x + len1 do
        num = num + 1
        xy[num] = {i, y}
        num = num + 1
        xy[num] = {i, y + len2}
        num = num + 1
        xy[num] = {i, y - len2}
      end
      for i = 1, len2 - 1 do
        xy[num + 1] = {x, y + i}
        xy[num + 2] = {x, y - i}
        xy[num + 3] = {x - len1, y + i}
        xy[num + 4] = {x - len1, y - i}
        xy[num + 5] = {x + len1, y + i}
        xy[num + 6] = {x + len1, y - i}
        num = num + 6
      end
    end
  elseif kind == 8 then
    xy[1] = {x, y}
    num = 1
    for i = 1, len1 do
      xy[num + 1] = {x + i, y}
      xy[num + 2] = {x - i, y}
      xy[num + 3] = {x, y + i}
      xy[num + 4] = {x, y - i}
      xy[num + 5] = {x + i, y + len1}
      xy[num + 6] = {x - i, y - len1}
      xy[num + 7] = {x + len1, y - i}
      xy[num + 8] = {x - len1, y + i}
      num = num + 8
    end
  elseif kind == 9 then
    xy[1] = {x, y}
    num = 1
    for i = 1, len1 do
      xy[num + 1] = {x + i, y}
      xy[num + 2] = {x - i, y}
      xy[num + 3] = {x, y + i}
      xy[num + 4] = {x, y - i}
      xy[num + 5] = {x - i, y + len1}
      xy[num + 6] = {x + i, y - len1}
      xy[num + 7] = {x + len1, y + i}
      xy[num + 8] = {x - len1, y - i}
      num = num + 8
    end
  elseif x == x0 and y == y0 then
    return 0
  elseif kind == 10 then
    if not len2 then
      len2 = 0
    end
    if not len3 then
      len3 = 0
    end
    if not len4 then
      len4 = 0
    end
    local fx, fy = x - x0, y - y0
    if fx > 0 then
      fx = 1
    elseif fx < 0 then
      fx = -1
    end
    if fy > 0 then
      fy = 1
    elseif fy < 0 then
      fy = -1
    end
    local dx1, dy1, dx2, dy2 = -fy, fx, fy, -fx
    dx1 = -(dx1 + fx) / 2
    dx2 = -(dx2 + fx) / 2
    dy1 = -(dy1 + fy) / 2
    dy2 = -(dy2 + fy) / 2
    if dx1 > 0 then
      dx1 = 1
    elseif dx1 < 0 then
      dx1 = -1
    end
    if dx2 > 0 then
      dx2 = 1
    elseif dx2 < 0 then
      dx2 = -1
    end
    if dy1 > 0 then
      dy1 = 1
    elseif dy1 < 0 then
      dy1 = -1
    end
    if dy2 > 0 then
      dy2 = 1
    elseif dy2 < 0 then
      dy2 = -1
    end
    for i = 0, len1 - 1 do
      num = num + 1
      xy[num] = {x + i * fx, y + i * fy}
    end
    for i = 0, len2 - 1 do
      num = num + 1
      xy[num] = {x + dx1 + i * fx, y + dy1 + i * fy}
      num = num + 1
      xy[num] = {x + dx2 + i * fx, y + dy2 + i * fy}
    end
    for i = 0, len3 - 1 do
      num = num + 1
      xy[num] = {x + 2 * dx1 + i * fx, y + 2 * dy1 + i * fy}
      num = num + 1
      xy[num] = {x + 2 * dx2 + i * fx, y + 2 * dy2 + i * fy}
    end
    for i = 0, len4 - 1 do
      num = num + 1
      xy[num] = {x + 3 * dx1 + i * fx, y + 3 * dy1 + i * fy}
      num = num + 1
      xy[num] = {x + 3 * dx2 + i * fx, y + 3 * dy2 + i * fy}
    end
  elseif kind == 11 then
    local fx, fy = x - x0, y - y0
    if fx > 1 then
      fx = 1
    elseif fx < -1 then
      fx = -1
    end
    if fy > 1 then
      fy = 1
    elseif fy < -1 then
      fy = -1
    end
    local dx1, dy1, dx2, dy2 = -fy, fx, fy, -fx
    if fx ~= 0 and fy ~= 0 then
      dx1 = -(dx1 + fx) / 2
      dx2 = -(dx2 + fx) / 2
      dy1 = -(dy1 + fy) / 2
      dy2 = -(dy2 + fy) / 2
      len1 = math.modf(len1 * 0.7071)
      for i = 0, len1 do
        num = num + 1
        xy[num] = {x + i * fx, y + i * fy}
        for j = 1, 2 * i + 1 do
          num = num + 1
          xy[num] = {x + i * fx + j * (dx1), y + i * fy + j * (dy1)}
          num = num + 1
          xy[num] = {x + i * fx + j * (dx2), y + i * fy + j * (dy2)}
        end
      end
    else
      for i = 0, len1 do
        num = num + 1
        xy[num] = {x + i * fx, y + i * fy}
        for j = 1, len1 - i do
          num = num + 1
          xy[num] = {x + i * fx + j * (dx1), y + i * fy + j * (dy1)}
          num = num + 1
          xy[num] = {x + i * fx + j * (dx2), y + i * fy + j * (dy2)}
        end
      end
    end
  elseif kind == 12 then
    local fx, fy = x - x0, y - y0
    if fx > 1 then
      fx = 1
    elseif fx < -1 then
      fx = -1
    end
    if fy > 1 then
      fy = 1
    elseif fy < -1 then
      fy = -1
    end
    local dx1, dy1, dx2, dy2 = -fy, fx, fy, -fx
    if fx ~= 0 and fy ~= 0 then
      dx1 = (dx1 + fx) / 2
      dx2 = (dx2 + fx) / 2
      dy1 = (dy1 + fy) / 2
      dy2 = (dy2 + fy) / 2
      len1 = math.modf(len1 * 1.41421)
      for i = 0, len1 do
        if i <= len1 / 2 then
          num = num + 1
          xy[num] = {x + i * fx, y + i * fy}
        end
        for j = 1, len1 - i * 2 do
          num = num + 1
          xy[num] = {x + i * fx + j * (dx1), y + i * fy + j * (dy1)}
          num = num + 1
          xy[num] = {x + i * fx + j * (dx2), y + i * fy + j * (dy2)}
        end
      end
    else
      for i = 0, len1 do
        num = num + 1
        xy[num] = {x + i * fx, y + i * fy}
        for j = 1, i do
          num = num + 1
          xy[num] = {x + i * fx + j * (dx1), y + i * fy + j * (dy1)}
          num = num + 1
          xy[num] = {x + i * fx + j * (dx2), y + i * fy + j * (dy2)}
        end
      end
    end
  elseif kind == 13 then
    local fx, fy = x - x0, y - y0
    if fx > 1 then
      fx = 1
    elseif fx < -1 then
      fx = -1
    end
    if fy > 1 then
      fy = 1
    elseif fy < -1 then
      fy = -1
    end
    local xx = x + fx * len1
    local yy = y + fy * len1
    for tx = xx - len1, xx + len1 do
      for ty = yy - len1, yy + len1 do
        if len1 < math.abs(tx - xx) + math.abs(ty - yy) then
          break;
        end
        num = num + 1
        xy[num] = {tx, ty}
      end
    end
  else
    return 0
  end

  if flag == 1 then
    local thexy = function(nx, ny, x, y)
	    local dx, dy = nx - x, ny - y
	    local hb = lib.GetS(JY.SubScene, nx, ny, 4)
	    return CC.ScreenW / 2 + CC.XScale * (dx - dy), CC.ScreenH / 2 + CC.YScale * (dx + dy) - hb
    end

    for i = 1, num do
    	if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
      	local tx, ty = thexy(xy[i][1], xy[i][2], x0, y0)

	      if GetWarMap(xy[i][1], xy[i][2], 2) ~= nil and GetWarMap(xy[i][1], xy[i][2], 2) >= 0 and GetWarMap(xy[i][1], xy[i][2], 2) ~= WAR.CurID then
				if not inteam(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]) and WAR.Person[WAR.CurID]["我方"] then
		      	local x0 = WAR.Person[WAR.CurID]["坐标X"];
		      	local y0 = WAR.Person[WAR.CurID]["坐标Y"];
		      	local dx = xy[i][1] - x0
		        local dy = xy[i][2] - y0
		        local size = CC.FontSmall;
		        local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
		        local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

		        local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

		        ry = ry - hb - CC.ScreenH/6;

		        if ry < 1 then			--加上这个，防止看不到血的情况
		        	ry = 1;
		        end

		      	--显示选中人物的生命值
		      	local color = RGB(245, 251, 5);
		      	local hp = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]]["生命"];
		      	local maxhp = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]]["生命最大值"];

		      	local ns = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]]["受伤程度"];
		      	local zd = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]]["中毒程度"];
		      	local len = #(string.format("%d/%d",hp,maxhp));
		      	rx = rx - len*size/4;

		      	--颜色根据所受的内伤确定
		      	if ns < 33 then
					color = RGB(236, 200, 40)
				elseif ns < 66 then
					color = RGB(244, 128, 32)
				else
					color = RGB(232, 32, 44)
				end

		      	DrawString(rx, ry, string.format("%d",hp), color, size);
		      	DrawString(rx + #string.format("%d",hp)*size/2, ry, "/", C_GOLD, size);

		      	if zd == 0 then
				      color = RGB(252, 148, 16)
				    elseif zd < 50 then
				      color = RGB(120, 208, 88)
				    else
				      color = RGB(56, 136, 36)
				    end
				    DrawString(rx + #string.format("%d",hp)*size/2 + size/2 , ry, string.format("%d", maxhp), color, size)
		      end

	      	--lib.PicLoadCache(0, 0, tx, ty, 2, 200)
	      else
	      	--lib.PicLoadCache(0, 0, tx, ty, 2, 112)
	      end

	    end
    end

  elseif flag == 2 then
    local diwo = WAR.Person[WAR.CurID]["我方"]
    local atknum = 0
    for i = 1, num do
      if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
        local id = GetWarMap(xy[i][1], xy[i][2], 2)

	      if id ~= -1 and id ~= WAR.CurID then
	        local xa, xb, xc = nil, nil, nil
	        if diwo ~= WAR.Person[id]["我方"] then
	          xa = 2
	        else
	          if GetS(0, 0, 0, 0) == 1 then
	            xa = -0.5
		        else
		          xa = 0
		        end
	        end
	        local hp = JY.Person[WAR.Person[id]["人物编号"]]["生命"]
	        if hp < atk / 6 then
	          xb = 2
	        elseif hp < atk / 3 then
	          xb = 1
	        else
	          xb = 0
	        end
	        local danger = JY.Person[WAR.Person[id]["人物编号"]]["内力最大值"]
	        xc = danger / 500
	        atknum = atknum + xa * math.modf(xb * (xc) + 5)
	      end
      end
    end
    return atknum
  elseif flag == 3 then
    for i = 1, num do
    	if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
      	SetWarMap(xy[i][1], xy[i][2], 4, 1)
      end
    end
	--武功选择范围
  elseif flag == 4 then
    for i = 1, num do
    	if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
			if GetWarMap(xy[i][1], xy[i][2], 2) ~= nil and GetWarMap(xy[i][1], xy[i][2], 2) >= 0 then
				--七夕龙女的论剑奖励代表是否学有迷踪步
				--自动不触发
				if WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"] == 0 and JY.Person[615]["论剑奖励"] == 1 and math.random(10) < 4 and WAR.AutoFight == 0 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["我方"] then
					--用阿凡提的品德作为触发迷踪步的判定
					JY.Person[606]["品德"] = 90
				end
				--小昭影步
				if match_ID(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"], 66) and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["我方"] then
					--用小昭的品德作为触发影步的判定
					JY.Person[66]["品德"] = 90
				end
				--畅想张无忌逆转乾坤
				--自动不触发
				if WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"] == 0 and JY.Base["畅想"] == 9 and PersonKF(0, 97) and WAR.AutoFight == 0 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["我方"] then
					--基础35%几率
					local chance = 36
					--每本天书+1几率
					chance = chance + JY.Base["天书数量"]
					if WAR.LQZ[0] == 100 then
						chance = chance + 10
					end
					if math.random(100) < chance then
						JY.Person[614]["品德"] = 90
					end
				end
				--命中的敌方的点为2
				if not inteam(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["人物编号"]) and WAR.Person[WAR.CurID]["我方"] then
					SetWarMap(xy[i][1], xy[i][2], 7, 2)
				else
					SetWarMap(xy[i][1], xy[i][2], 7, 1)
				end
			else
				SetWarMap(xy[i][1], xy[i][2], 7, 1)
			end
		end
    end
  end
end

PNLBD = {}

--飞邪胡斐
PNLBD[0] = function()
  JY.Person[1]["生命"] = 800
  JY.Person[1]["生命最大值"] = 800
  JY.Person[1]["内力"] = 4000
  JY.Person[1]["内力最大值"] = 4000
  JY.Person[1]["攻击力"] = 130
  JY.Person[1]["防御力"] = 130
  JY.Person[1]["轻功"] = 160
  JY.Person[1]["受伤程度"] = 0
  JY.Person[1]["中毒程度"] = 0
  JY.Person[1]["武功1"] = 67
  JY.Person[1]["武功等级1"] = 999
  JY.Person[1]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--飞正阎基
PNLBD[1] = function()
  JY.Person[4]["生命"] = 330
  JY.Person[4]["生命最大值"] = 330
  JY.Person[4]["内力"] = 1200
  JY.Person[4]["内力最大值"] = 1200
  JY.Person[4]["武功等级1"] = 700
  JY.Person[4]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--杀林平之
PNLBD[34] = function()
  JY.Person[36]["生命"] = 650
  JY.Person[36]["生命最大值"] = 650
  JY.Person[36]["内力"] = 3000
  JY.Person[36]["内力最大值"] = 3000
  JY.Person[36]["攻击力"] = 180
  JY.Person[36]["防御力"] = 130
  JY.Person[36]["轻功"] = 220
  JY.Person[36]["受伤程度"] = 0
  JY.Person[36]["中毒程度"] = 0
  JY.Person[36]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--神邪战杨龙
PNLBD[75] = function()
  JY.Person[58]["生命"] = 850
  JY.Person[58]["生命最大值"] = 850
  JY.Person[58]["内力"] = 4000
  JY.Person[58]["内力最大值"] = 4000
  JY.Person[58]["攻击力"] = 210
  JY.Person[58]["防御力"] = 180
  JY.Person[58]["轻功"] = 160
  JY.Person[58]["受伤程度"] = 0
  JY.Person[58]["中毒程度"] = 0
  JY.Person[58]["武功1"] = 45		--玄铁
  JY.Person[58]["武功2"] = 104		--逆运
  JY.Person[58]["武功3"] = 107		--九阴
  JY.Person[58]["武功等级1"] = 999
  JY.Person[58]["武功等级2"] = 999
  JY.Person[58]["武功等级3"] = 400
  JY.Person[58]["血量翻倍"] = JY.Person[592]["血量翻倍"]
  JY.Person[59]["生命"] = 750
  JY.Person[59]["生命最大值"] = 750
  JY.Person[59]["内力"] = 3500
  JY.Person[59]["内力最大值"] = 3500
  JY.Person[59]["攻击力"] = 170
  JY.Person[59]["防御力"] = 150
  JY.Person[59]["轻功"] = 200
  JY.Person[59]["受伤程度"] = 0
  JY.Person[59]["中毒程度"] = 0
  JY.Person[59]["武功3"] = 107		--九阴
  JY.Person[59]["武功等级3"] = 400
  JY.Person[59]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--招亲郭靖
PNLBD[76] = function()
	JY.Person[55]["武功1"] = 26
	JY.Person[55]["武功等级1"] = 600
    JY.Person[55]["武功2"] = 15
	JY.Person[55]["武功等级2"] = 500
    JY.Person[55]["武功3"] = 107
	JY.Person[55]["武功等级3"] = 50
	JY.Person[55]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--书邪陈家洛
PNLBD[138] = function()
  JY.Person[75]["生命"] = 650
  JY.Person[75]["生命最大值"] = 650
  JY.Person[75]["内力"] = 3000
  JY.Person[75]["内力最大值"] = 3000
  JY.Person[75]["攻击力"] = 140
  JY.Person[75]["防御力"] = 120
  JY.Person[75]["轻功"] = 130
  JY.Person[75]["受伤程度"] = 0
  JY.Person[75]["中毒程度"] = 0
  JY.Person[75]["武功等级1"] = 999
  JY.Person[75]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--碧邪
PNLBD[165] = function()
	--袁承志
	JY.Person[54]["生命"] = 750
	JY.Person[54]["生命最大值"] = 750
	JY.Person[54]["内力"] = 4000
	JY.Person[54]["内力最大值"] = 4000
	JY.Person[54]["攻击力"] = 140
	JY.Person[54]["防御力"] = 140
	JY.Person[54]["轻功"] = 90
	JY.Person[54]["受伤程度"] = 0
	JY.Person[54]["中毒程度"] = 0
	JY.Person[54]["个人觉醒"] = 1
	JY.Person[54]["携带物品1"] = -1
	JY.Person[54]["携带物品2"] = -1
	JY.Person[54]["携带物品数量1"] = 0
	JY.Person[54]["携带物品数量2"] = 0
	JY.Person[54]["血量翻倍"] = JY.Person[592]["血量翻倍"]
	--温青青
	JY.Person[91]["生命"] = 600
	JY.Person[91]["生命最大值"] = 600
	JY.Person[91]["内力"] = 2500
	JY.Person[91]["内力最大值"] = 2500
	JY.Person[91]["攻击力"] = 110
	JY.Person[91]["防御力"] = 110
	JY.Person[91]["轻功"] = 70
	JY.Person[91]["受伤程度"] = 0
	JY.Person[91]["中毒程度"] = 0
	JY.Person[91]["武功1"] = 40
	JY.Person[91]["武功等级1"] = 999
	JY.Person[91]["武功2"] = 90
	JY.Person[91]["武功等级2"] = 999
	JY.Person[91]["天赋内功"] = 90
	for i = 3 , 12 do
		JY.Person[91]["武功"..i] = 0
		JY.Person[91]["武功等级"..i] = 0
	end
	JY.Person[91]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--侠邪石破天
PNLBD[170] = function()
  JY.Person[38]["生命"] = 950
  JY.Person[38]["生命最大值"] = 950
  JY.Person[38]["内力"] = 5000
  JY.Person[38]["内力最大值"] = 5000
  JY.Person[38]["攻击力"] = 200
  JY.Person[38]["防御力"] = 200
  JY.Person[38]["轻功"] = 160
  JY.Person[38]["受伤程度"] = 0
  JY.Person[38]["中毒程度"] = 0
  JY.Person[38]["武功等级1"] = 999
  JY.Person[38]["武功2"] = 102
  JY.Person[38]["武功等级2"] = 999
  JY.Person[38]["天赋内功"] = 102
  JY.Person[38]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--天正游坦之
PNLBD[197] = function()
  JY.Person[48]["生命"] = 850
  JY.Person[48]["生命最大值"] = 850
  JY.Person[48]["内力"] = 3000
  JY.Person[48]["内力最大值"] = 3000
  JY.Person[48]["攻击力"] = 150
  JY.Person[48]["防御力"] = 130
  JY.Person[48]["轻功"] = 100
  JY.Person[48]["受伤程度"] = 0
  JY.Person[48]["中毒程度"] = 0
  JY.Person[48]["武功等级1"] = 999
  JY.Person[48]["武功等级2"] = 999
  JY.Person[48]["武功2"] = 108
  JY.Person[48]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--天正慕容复
PNLBD[198] = function()
  JY.Person[51]["生命"] = 750
  JY.Person[51]["生命最大值"] = 750
  JY.Person[51]["内力"] = 3000
  JY.Person[51]["内力最大值"] = 3000
  JY.Person[51]["攻击力"] = 180
  JY.Person[51]["防御力"] = 160
  JY.Person[51]["轻功"] = 120
  JY.Person[51]["受伤程度"] = 0
  JY.Person[51]["中毒程度"] = 0
  JY.Person[51]["武功等级1"] = 999
  JY.Person[51]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--天邪二
PNLBD[250] = function()
	--段誉
	JY.Person[53]["生命"] = 750
	JY.Person[53]["生命最大值"] = 750
	JY.Person[53]["内力"] = 9999
	JY.Person[53]["内力最大值"] = 9999
	JY.Person[53]["攻击力"] = 160
	JY.Person[53]["防御力"] = 150
	JY.Person[53]["轻功"] = 120
	JY.Person[53]["武功1"] = 85
	JY.Person[53]["武功等级1"] = 999
	JY.Person[53]["武功2"] = 147
	JY.Person[53]["武功等级2"] = 999
	JY.Person[53]["武功3"] = 49
	JY.Person[53]["武功等级3"] = 999
	JY.Person[53]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--天邪三
PNLBD[251] = function()
	--虚竹
	JY.Person[49]["生命"] = 800
	JY.Person[49]["生命最大值"] = 800
	JY.Person[49]["内力"] = 8500
	JY.Person[49]["内力最大值"] = 8500
	JY.Person[49]["攻击力"] = 150
	JY.Person[49]["防御力"] = 170
	JY.Person[49]["轻功"] = 80
	JY.Person[49]["受伤程度"] = 0
	JY.Person[49]["中毒程度"] = 0
	JY.Person[49]["武功1"] = 8
	JY.Person[49]["武功等级1"] = 999
	JY.Person[49]["武功2"] = 98
	JY.Person[49]["武功等级2"] = 999
	JY.Person[49]["武功3"] = 14
	JY.Person[49]["武功等级3"] = 999
	JY.Person[49]["武功4"] = 101
	JY.Person[49]["武功等级4"] = 999
	for i = 5 , 12 do
		JY.Person[49]["武功"..i] = 0
		JY.Person[49]["武功等级"..i] = 0
	end
	JY.Person[49]["个人觉醒"] = 1
	JY.Person[49]["左右互搏"] = 0
	JY.Person[49]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--连邪水笙
PNLBD[42] = function()
	JY.Person[589]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

PNLBD[252] = function()
	JY.Person[589]["生命最大值"] = 650
	JY.Person[589]["生命"] = JY.Person[589]["生命最大值"]
	JY.Person[589]["内力最大值"] = 2500
	JY.Person[589]["内力"] = JY.Person[589]["内力最大值"]
	JY.Person[589]["防御力"] = 130
	JY.Person[589]["轻功"] = 120
	JY.Person[589]["武功等级1"] = 999
end

--倚邪张无忌
PNLBD[288] = function()
	JY.Person[9]["生命最大值"] = 999
	JY.Person[9]["生命"] = JY.Person[9]["生命最大值"]
	JY.Person[9]["内力最大值"] = 5000
	JY.Person[9]["内力"] = JY.Person[9]["内力最大值"]
	JY.Person[9]["攻击力"] = 220
	JY.Person[9]["防御力"] = 200
	JY.Person[9]["轻功"] = 200
	JY.Person[9]["武功等级1"] = 999
	JY.Person[9]["武功等级2"] = 999
	JY.Person[9]["武功3"] = 97
	JY.Person[9]["武功等级3"] = 900
	JY.Person[9]["武功4"] = 16
	JY.Person[9]["武功等级4"] = 999
	JY.Person[9]["武功5"] = 46
	JY.Person[9]["武功等级5"] = 999
	JY.Person[9]["武功6"] = 93
	JY.Person[9]["武功等级6"] = 900
	JY.Person[9]["携带物品1"] = -1
	JY.Person[9]["携带物品数量1"] = 0
	JY.Person[9]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--何铁手
--正线
PNLBD[162] = function()
  JY.Person[83]["生命"] = 600
  JY.Person[83]["生命最大值"] = 600
  JY.Person[83]["内力"] = 3500
  JY.Person[83]["内力最大值"] = 3500
  JY.Person[83]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end
--邪线
PNLBD[164] = function()
  JY.Person[83]["生命"] = 600
  JY.Person[83]["生命最大值"] = 600
  JY.Person[83]["内力"] = 3500
  JY.Person[83]["内力最大值"] = 3500
  JY.Person[83]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--书正张召重
PNLBD[142] = function()
	JY.Person[80]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--书邪霍青桐
PNLBD[140] = function()
	JY.Person[74]["生命"] = 500
	JY.Person[74]["生命最大值"] = 500
	JY.Person[74]["内力"] = 1500
	JY.Person[74]["内力最大值"] = 1500
	JY.Person[74]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--鸳邪萧中慧
PNLBD[132] = function()
	JY.Person[77]["生命"] = 500
	JY.Person[77]["生命最大值"] = 500
	JY.Person[77]["内力"] = 1500
	JY.Person[77]["内力最大值"] = 1500
	JY.Person[77]["武功等级1"] = 999
	JY.Person[77]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--迷之少女挑战刀剑双绝
PNLBD[280] = function()
	--苗人凤
	JY.Person[3]["武功2"] = 67
	JY.Person[3]["武功等级2"] = 999
	JY.Person[3]["携带物品1"] = -1
	JY.Person[3]["携带物品2"] = -1
	JY.Person[3]["携带物品3"] = -1
	JY.Person[3]["携带物品数量1"] = 0
	JY.Person[3]["携带物品数量2"] = 0
	JY.Person[3]["携带物品数量3"] = 0
end

--射邪一灯居
PNLBD[68] = function()
	--郭靖
	JY.Person[55]["生命"] = 800
	JY.Person[55]["生命最大值"] = 800
	--黄蓉
	JY.Person[56]["生命"] = 700
	JY.Person[56]["生命最大值"] = 700
	JY.Person[56]["内力"] = 3000
	JY.Person[56]["内力最大值"] = 3000
	JY.Person[56]["携带物品1"] = -1
	JY.Person[56]["携带物品2"] = -1
	JY.Person[56]["携带物品3"] = -1
	JY.Person[56]["携带物品数量1"] = 0
	JY.Person[56]["携带物品数量2"] = 0
	JY.Person[56]["携带物品数量3"] = 0
	JY.Person[56]["血量翻倍"] = JY.Person[592]["血量翻倍"]
end

--神正杨过单金轮
PNLBD[275] = function()
	JY.Person[62]["武功3"] = 169
	JY.Person[62]["武功等级3"] = 999
	JY.Person[62]["天赋内功"] = 169
end

--战四大山
PNLBD[290] = function()
	--远古神蛤
	JY.Person[190]["姓名"] = "远古神蛤"
	JY.Person[190]["生命"] = 999
	JY.Person[190]["生命最大值"] = 999
	JY.Person[190]["内力"] = 7000
	JY.Person[190]["内力最大值"] = 7000
	JY.Person[190]["内力性质"] = 2
	JY.Person[190]["攻击力"] = 200
	JY.Person[190]["防御力"] = 200
	JY.Person[190]["轻功"] = 150
	JY.Person[190]["武功1"] = 22
	JY.Person[190]["武功等级1"] = 999
	JY.Person[190]["武功2"] = 108
	JY.Person[190]["武功等级2"] = 999
	JY.Person[190]["武功3"] = 145
	JY.Person[190]["武功等级3"] = 999
	JY.Person[190]["武功4"] = 96
	JY.Person[190]["武功等级4"] = 999
	JY.Person[190]["武功5"] = 144
	JY.Person[190]["武功等级5"] = 999
	JY.Person[190]["天赋外功1"] = 22
	JY.Person[190]["天赋内功"] = 108
	JY.Person[190]["天赋轻功"] = 145
	--亿年雪人
	JY.Person[429]["姓名"] = "亿年雪人"
	JY.Person[429]["生命"] = 999
	JY.Person[429]["生命最大值"] = 999
	JY.Person[429]["内力"] = 9999
	JY.Person[429]["内力最大值"] = 9999
	JY.Person[429]["内力性质"] = 0
	JY.Person[429]["攻击力"] = 300
	JY.Person[429]["防御力"] = 150
	JY.Person[429]["轻功"] = 100
	JY.Person[429]["武功1"] = 156
	JY.Person[429]["武功等级1"] = 999
	JY.Person[429]["武功2"] = 107
	JY.Person[429]["武功等级2"] = 999
	JY.Person[429]["武功3"] = 148
	JY.Person[429]["武功等级3"] = 999
	JY.Person[429]["武功4"] = 87
	JY.Person[429]["武功等级4"] = 999
	JY.Person[429]["武功5"] = 92
	JY.Person[429]["武功等级5"] = 999
	JY.Person[429]["天赋外功1"] = 156
	JY.Person[429]["天赋内功"] = 107
	JY.Person[429]["天赋轻功"] = 148
	--蜘蛛尊者
	JY.Person[439]["姓名"] = "蜘蛛尊者"
	JY.Person[439]["生命"] = 999
	JY.Person[439]["生命最大值"] = 999
	JY.Person[439]["内力"] = 8500
	JY.Person[439]["内力最大值"] = 8500
	JY.Person[439]["内力性质"] = 1
	JY.Person[439]["攻击力"] = 150
	JY.Person[439]["防御力"] = 300
	JY.Person[439]["轻功"] = 100
	JY.Person[439]["武功1"] = 66
	JY.Person[439]["武功等级1"] = 999
	JY.Person[439]["武功2"] = 106
	JY.Person[439]["武功等级2"] = 999
	JY.Person[439]["武功3"] = 147
	JY.Person[439]["武功等级3"] = 999
	JY.Person[439]["武功4"] = 169
	JY.Person[439]["武功等级4"] = 999
	JY.Person[439]["武功5"] = 94
	JY.Person[439]["武功等级5"] = 999
	JY.Person[439]["天赋外功1"] = 66
	JY.Person[439]["天赋内功"] = 106
	JY.Person[439]["天赋轻功"] = 147
end

--剑魔剑仙
PNLBD[291] = function()
	--阿青
	JY.Person[604]["内力"] = 9999
	JY.Person[604]["内力最大值"] = 9999
	JY.Person[604]["防御力"] = 300
	JY.Person[604]["轻功"] = 400
	JY.Person[604]["御剑能力"] = 320
end

--二十大
PNLBD[289] = function()
	--王重阳
	JY.Person[129]["武功2"] = 107
	JY.Person[129]["天赋内功"] = 107
	JY.Person[129]["天赋轻功"] = 148
	JY.Person[129]["内力性质"] = 0
	--黄药师
	JY.Person[57]["武功2"] = 107
	JY.Person[57]["武功等级2"] = 999
	JY.Person[57]["天赋内功"] = 107
	JY.Person[57]["武功3"] = 12
	JY.Person[57]["武功等级3"] = 999
	JY.Person[57]["武功4"] = 38
	JY.Person[57]["武功等级4"] = 999
	JY.Person[57]["内力"] = 5000
	JY.Person[57]["内力最大值"] = 5000
	JY.Person[57]["内力性质"] = 0
	--欧阳锋
	JY.Person[60]["武功3"] = 81
	JY.Person[60]["武功等级3"] = 999
	JY.Person[60]["武功4"] = 107
	JY.Person[60]["武功等级4"] = 999
	JY.Person[60]["内力"] = 5000
	JY.Person[60]["内力最大值"] = 5000
	JY.Person[60]["内力性质"] = 0
	--一灯
	JY.Person[65]["天赋内功"] = 107
	JY.Person[65]["武功3"] = 107
	JY.Person[65]["武功等级3"] = 999
	JY.Person[65]["内力"] = 5000
	JY.Person[65]["内力最大值"] = 5000
	JY.Person[65]["内力性质"] = 0
	--洪七公
	JY.Person[69]["天赋内功"] = 107
	JY.Person[69]["武功3"] = 107
	JY.Person[69]["武功等级3"] = 999
	JY.Person[69]["内力"] = 5000
	JY.Person[69]["内力最大值"] = 5000
	JY.Person[69]["内力性质"] = 0
	--周伯通
	JY.Person[64]["武功等级2"] = 999
	JY.Person[64]["内力性质"] = 0
	JY.Person[64]["武功3"] = 16
	JY.Person[64]["武功等级3"] = 999
	--风清扬
	JY.Person[140]["武功3"] = 108
	JY.Person[140]["武功等级3"] = 999
	JY.Person[140]["天赋内功"] = 108
	--金轮
	JY.Person[62]["武功3"] = 169
	JY.Person[62]["武功等级3"] = 999
	JY.Person[62]["天赋内功"] = 169
	JY.Person[62]["内力"] = 5000
	JY.Person[62]["内力最大值"] = 5000
	--张三丰
	JY.Person[5]["内力"] = 7000
	JY.Person[5]["内力最大值"] = 7000
	--慕容博
	JY.Person[113]["攻击力"] = 150
	JY.Person[113]["防御力"] = 150
	JY.Person[113]["武功3"] = 108
	JY.Person[113]["武功等级3"] = 999
	JY.Person[113]["天赋内功"] = 108
	--萧远山
	JY.Person[112]["武功3"] = 108
	JY.Person[112]["武功等级3"] = 999
	JY.Person[112]["天赋内功"] = 108
	JY.Person[112]["内力"] = 6000
	JY.Person[112]["内力最大值"] = 6000
	--鸠摩智
	JY.Person[103]["武功3"] = 108
	JY.Person[103]["武功等级3"] = 999
	JY.Person[103]["天赋内功"] = 108
	JY.Person[103]["内力"] = 6000
	JY.Person[103]["内力最大值"] = 6000
	JY.Person[103]["生命"] = 900
	JY.Person[103]["生命最大值"] = 900
	--乔峰
	JY.Person[50]["武功3"] = 108
	JY.Person[50]["武功等级3"] = 999
	JY.Person[50]["天赋内功"] = 108
	JY.Person[50]["天赋轻功"] = 145
	--扫地老僧
	JY.Person[114]["武功2"] = 106
	JY.Person[114]["武功等级2"] = 999
	JY.Person[114]["武功3"] = 107
	JY.Person[114]["武功等级3"] = 999
end

--笑正
PNLBD[297] = function()
	--左冷禅
	JY.Person[22]["生命"] = 800
	JY.Person[22]["生命最大值"] = 800
	JY.Person[22]["武功2"] = 30
	JY.Person[22]["武功等级2"] = 999
	JY.Person[22]["武功3"] = 31
	JY.Person[22]["武功等级3"] = 999
	JY.Person[22]["武功4"] = 32
	JY.Person[22]["武功等级4"] = 999
	JY.Person[22]["武功5"] = 34
	JY.Person[22]["武功等级5"] = 999
	JY.Person[22]["武功6"] = 175
	JY.Person[22]["武功等级6"] = 900
	--林平之
	JY.Person[36]["生命"] = 700
	JY.Person[36]["生命最大值"] = 700
	JY.Person[36]["内力"] = 4800
	JY.Person[36]["内力最大值"] = 4800
	JY.Person[36]["武功等级1"] = 999
end

--三挑岳不群
PNLBD[298] = function()
	JY.Person[19]["生命"] = 900
	JY.Person[19]["生命最大值"] = 900
	JY.Person[19]["攻击力"] = 250
	JY.Person[19]["防御力"] = 250
	JY.Person[19]["轻功"] = 270
	JY.Person[19]["天赋内功"] = 105
	JY.Person[19]["武功3"] = 175
	JY.Person[19]["武功等级3"] = 900
end

--战斗开始修正朝向问题
function WarFixBack()
	for j = 0, WAR.PersonNum - 1 do
		local i = War_AutoSelectEnemy_near(j)
		--lib.Debug(j.."start"..i)
		if i >= 0 then
			WAR.Person[j]["人方向"] = War_Direct(WAR.Person[j]["坐标X"], WAR.Person[j]["坐标Y"],
				WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"])
			--WAR.Person[j]["贴图"] = WarCalPersonPic(j)
		end
	end
end

--黄蓉：奇门遁甲
function WarNewLand0()
	local baguax = 0
	local baguay = 0
	local lives = 0
	for j = 0, WAR.PersonNum - 1 do
		if not WAR.Person[j]["死亡"] then
			baguax = baguax + WAR.Person[j]["坐标X"]
			baguay = baguay + WAR.Person[j]["坐标Y"]
			lives = lives + 1
		end
	end
	baguax = math.modf(baguax / lives)
	baguay = math.modf(baguay / lives)
	WarNewLand(baguax, baguay)
end

function WarNewLand(x, y)
	--1绿色，2红色，3蓝色，4紫色
	CleanWarMap(6,-1);

	--在周围绘制奇阵
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
end

--战斗主函数
function WarMain(warid, isexp)
	WarLoad(warid)			--初始化战斗数据
	JY.SubScene = WAR.Data["地图"]
	WarSelectTeam_Enhance()	--选择我方（优化版）
	WarSelectEnemy()		--选择敌人

	Health_in_Battle()		--无酒不欢：血量翻倍

	if JY.Restart == 1 then
		return false
	end

	CleanMemory()
	lib.PicInit()
	lib.ShowSlow(20, 1)
	WarLoadMap(WAR.Data["地图"])	--加载战斗地图

	--默认在当前场景战斗
	local BattleField = JY.SubScene

	--倚天正线拿九阳战斗
	if WAR.ZDDH == 287 then
		BattleField = 116
	end

	for i = 0, CC.WarWidth-1 do
		for j = 0, CC.WarHeight-1 do
			lib.SetWarMap(i, j, 0, lib.GetS(BattleField, i, j, 0))
			lib.SetWarMap(i, j, 1, lib.GetS(BattleField, i, j, 1))
		end
	end

	--雪山落花流水战役
	if WAR.ZDDH == 42 then
		SetS(2, 24, 31, 1, 0)
		SetS(2, 30, 34, 1, 0)
		SetS(2, 27, 27, 1, 0)
	end

	--旧版华山论剑的擂台
	if WAR.ZDDH == 238 then
		for x = 24, 34 do
			for y = 24, 34 do
				lib.SetWarMap(x, y, 0, 1030)
			end
		end
		for y = 23, 35 do
			lib.SetWarMap(23, y, 1, 1174)
			lib.SetWarMap(35, y, 1, 1174)
		end
		for x = 24, 35 do
			lib.SetWarMap(x, 35, 1, 1174)
			lib.SetWarMap(x, 23, 1, 1174)
		end
		lib.SetWarMap(23, 23, 0, 1174)
		lib.SetWarMap(35, 35, 0, 1174)
		lib.SetWarMap(23, 35, 0, 1174)
		lib.SetWarMap(35, 23, 0, 1174)
		lib.SetWarMap(23, 23, 1, 2960)
		lib.SetWarMap(35, 35, 1, 2960)
		lib.SetWarMap(23, 35, 1, 2960)
		lib.SetWarMap(35, 23, 1, 2960)
	end

	--20大高手，修正地形
	if WAR.ZDDH == 289 then
		lib.SetWarMap(39, 29, 1, 1417*2)
		lib.SetWarMap(39, 30, 1, 1416*2)
		lib.SetWarMap(39, 31, 1, 1416*2)
		lib.SetWarMap(39, 32, 1, 1417*2)
		for i = 40, 43 do
			lib.SetWarMap(i, 30, 0, 35*2)
			lib.SetWarMap(i, 31, 0, 35*2)
			lib.SetWarMap(i, 32, 0, 35*2)
			lib.SetWarMap(i, 30, 1, 0)
			lib.SetWarMap(i, 32, 1, 0)
		end
		for i = 30, 32 do
			lib.SetWarMap(40, i, 0, 76*2)
			lib.SetWarMap(41, i, 0, 72*2)
		end
		lib.SetWarMap(15, 19, 1, 1843*2)
		lib.SetWarMap(15, 20, 1, 1843*2)
	end

	--战四大山，修正地形
	if WAR.ZDDH == 290 then
		for i = 5, 34 do
			lib.SetWarMap(7, i, 1, 0)
			lib.SetWarMap(9, i, 1, 0)
			lib.SetWarMap(54, i, 1, 0)
			lib.SetWarMap(56, i, 1, 0)
		end
	end

	--杀东方不败
	if WAR.ZDDH == 54 then
		lib.SetWarMap(11, 36, 1, 2)
	end

	--改变游戏状态
	JY.Status = GAME_WMAP

	--加载贴图文件
	lib.PicLoadFile(CC.WMAPPicFile[1], CC.WMAPPicFile[2], 0)						--战场贴图，内存区域0

	lib.LoadPNGPath(CC.HeadPath, 1, CC.HeadNum, limitX(CC.ScreenW/936*100,0,100))	--人物大头像，内存区域1

	lib.PicLoadFile(CC.ThingPicFile[1], CC.ThingPicFile[2], 2, 100, 100)			--物品贴图，内存区域2

	lib.PicLoadFile(CC.EFTFile[1], CC.EFTFile[2], 3)								--特效贴图，内存区域3

	lib.LoadPNGPath(CC.IconPath, 98, CC.IconNum, limitX(CC.ScreenW/936*100,0,100))	--状态图标，内存区域98

	lib.LoadPNGPath(CC.HeadPath, 99, CC.HeadNum, 26.923076923)						--人物小头像，用于集气条，内存区域99

	--无酒不欢：随机战斗音乐
	local zdyy = math.random(10) + 99

	--15大固定
	if WAR.ZDDH == 133 or WAR.ZDDH == 134 then
		zdyy = 27
	end

	--VS少林诸僧战固定
	if WAR.ZDDH == 80 then
		zdyy = 22
	end

	--葵花尊者战固定
	if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 then
		zdyy = 112
	end

	--蒙哥战固定
	if WAR.ZDDH == 278 then
		zdyy = 110
	end

	--武当战三丰固定
	if WAR.ZDDH == 22 then
		zdyy = 113
	end

	--20大高手战固定
	if WAR.ZDDH == 289 then
		zdyy = 115
	end

	--战四大山固定
	if WAR.ZDDH == 290 then
		zdyy = 117
	end

	--剑魔剑仙固定
	if WAR.ZDDH == 291 then
		zdyy = 118
	end

	PlayMIDI(zdyy)

	--PlayMIDI(WAR.Data["音乐"])  

	local warStatus = nil		 --战斗状态

	WarPersonSort()			--按轻功排序
	CleanWarMap(2, -1)
	CleanWarMap(6, -2)


	for i = 0, WAR.PersonNum - 1 do

		if i == 0 then
		  WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"] = WE_xy(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"])
		else
		  WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"] = WE_xy(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], i)
		end

		SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 2, i)

		local pid = WAR.Person[i]["人物编号"]
		lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[pid]["头像代号"]), string.format(CC.FightPicFile[2], JY.Person[pid]["头像代号"]), 4 + i)	--人物战斗动作贴图，内存区域4-29（一场战斗上限26人）

		--Alungky 用5000数组来保存头像数据
		--主角的数据要特殊处理
		if pid == 0 and JY.Base["畅想"] == 0 then
			if JY.Base["标准"] > 0 then
				if JY.Person[0]["性别"] == 0 then
					WAR.tmp[5000+i] = 280 + JY.Base["标准"]
				else
					WAR.tmp[5000+i] = 500 + JY.Base["标准"]
				end
			--特殊
			else
				if JY.Person[0]["性别"] == 0 then
					WAR.tmp[5000+i] = 290
				else
					WAR.tmp[5000+i] = 368
				end
			end
		else
			WAR.tmp[5000+i] = JY.Person[pid]["头像代号"]
		end
	end

	--轻功对移动格子的计算
	local function getnewmove(id)
		local mov = JY.Person[WAR.Person[id]["人物编号"]]["暗器技巧"]
		--余沧海青城掌门
		if WAR.Person[id]["人物编号"] == 24 then
			for j = 0, WAR.PersonNum - 1 do
				if id ~= j and WAR.Person[j]["我方"] == true and JY.Person[WAR.Person[j]["人物编号"]]["生命"] > 0 then
					mov = mov + 2
				end
			end
		end
		return mov
	end
	local function getdelay(x, y)
		return math.modf(1.5 * (x / y + y - 3))
	end
	WarFixBack()
	for i = 0, WAR.PersonNum - 1 do
		WAR.Person[i]["贴图"] = WarCalPersonPic(i)
	end
	WarSetPerson()
	WAR.CurID = 0
	WarDrawMap(0)
	lib.ShowSlow(20, 0)

	--无酒不欢：设置人物的初始集气位置
	for i = 0, WAR.PersonNum - 1 do
		WAR.Person[i].Time = 800 - i * 1000 / WAR.PersonNum

		--岳灵珊 每个剑法+50点初始集气
		if match_ID(WAR.Person[i]["人物编号"], 79) then
			local JF = 0
			local bh = WAR.Person[i]["人物编号"]
			for i = 1, CC.Kungfunum do
				if JY.Wugong[JY.Person[bh]["武功" .. i]]["武功类型"] == 3 then
					JF = JF + 1
				end
			end
			WAR.Person[i].Time = WAR.Person[i].Time + (JF) * 50
		end

		if WAR.Person[i].Time > 990 then
			WAR.Person[i].Time = 990
		end

		--令狐冲，一觉之后，初始满集气
		if match_ID_awakened(WAR.Person[i]["人物编号"], 35, 1) then
			WAR.Person[i].Time = 998
		end

		--独孤求败，初始满集气
		if match_ID(WAR.Person[i]["人物编号"], 592) then
			WAR.Person[i].Time = 999
		end

		--血刀老祖 初始集气900
		if match_ID(WAR.Person[i]["人物编号"], 97) then
			WAR.Person[i].Time = 900
		end

		--太监初始集气-200
		if JY.Person[WAR.Person[i]["人物编号"]]["性别"] == 2 then
			WAR.Person[i].Time = -200
		end

		--林平之 初始集气900
		if match_ID(WAR.Person[i]["人物编号"], 36) then
			WAR.Person[i].Time = 900
		end

		--木桩的初始集气
		if WAR.Person[i]["人物编号"] == 591 and WAR.ZDDH == 226 then
			WAR.Person[i].Time = 0
		end

		--圣火神功 初始集气加200和100随机
		local id = WAR.Person[i]["人物编号"]
		if PersonKF(id, 93) then
			WAR.Person[i].Time = WAR.Person[i].Time + 200 + math.random(100)
		end
		if WAR.Person[i].Time > 990 then
			WAR.Person[i].Time = 990
		end

		--论剑打赢阿凡提奖励，绝对先手
		if WAR.Person[i]["人物编号"] == 0 and JY.Person[606]["论剑奖励"] == 1 then
			for j = 0, WAR.PersonNum - 1 do
				WAR.Person[j].Time = WAR.Person[j].Time - 75
				if WAR.Person[j].Time > 990 then
					WAR.Person[j].Time = 990
				end
			end
			WAR.Person[i].Time = 1005
		end

		--移动步数在此
		WAR.Person[i]["移动步数"] = getnewmove(i)
		
		--[[if WAR.Person[i]["移动步数"] < 1 then
			WAR.Person[i]["移动步数"] = 1
		end]]
	end

	--携带物品的初始化
	for a = 0, WAR.PersonNum - 1 do
		for s = 1, 4 do
			if JY.Person[WAR.Person[a]["人物编号"]]["携带物品数量" .. s] == nil or JY.Person[WAR.Person[a]["人物编号"]]["携带物品数量" .. s] < 1 then
				JY.Person[WAR.Person[a]["人物编号"]]["携带物品" .. s] = -1
				JY.Person[WAR.Person[a]["人物编号"]]["携带物品数量" .. s] = 0;
			end
		end
	end

	--笑傲邪线，黑木崖如果单挑东方不败，则东方会以葵花尊者形态出战
	if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 then
		local dfid;
		for i = 0, WAR.PersonNum - 1 do
			local id = WAR.Person[i]["人物编号"]
			if id == 27 then
				dfid = i;
				break
			end
		end
		local orid = WAR.CurID
		WAR.CurID = dfid

		Cls()
		local KHZZ = {"面对本座","对方竟敢单独出战","伤自尊啊"}

		for i = 1, #KHZZ do
			lib.GetKey()
			DrawString(-1, -1, KHZZ[i], C_GOLD, CC.Fontsmall)
			ShowScreen()
			Cls()
			lib.Delay(1000)
		end

		CurIDTXDH(WAR.CurID, 7, 1)

		lib.Background(0,200,CC.ScreenW,400,78)
		NewDrawString(CC.ScreenW, CC.ScreenH/2 + 160, "葵花诀尊者形态", C_GOLD, 80)
		NewDrawString(CC.ScreenW, CC.ScreenH/2 + 360, "看吧 东方在赤红的燃烧", C_RED, 70)

		ShowScreen()
		Cls()
		lib.Delay(2000)

		local KHZZ2 = {"不知死活的"..JY.Person[0]["外号2"],"好好体验一下死亡的恐怖吧"}

		for i = 1, #KHZZ2 do
			lib.GetKey()
			DrawString(-1, -1, KHZZ2[i], C_GOLD, CC.Fontsmall)
			ShowScreen()
			Cls()
			lib.Delay(1000)
		end

		WAR.CurID = orid
	end

	--圣火三使战开局的文字特效
	if WAR.ZDDH == 14 then
		say("Ｇ１妙风使！", 173, 0)   --妙风使
		say("Ｇ１流云使！", 174, 1)   --流云使
		say("Ｇ１辉月使！Ｈ圣火三绝阵！", 175, 5)   --辉月使！Ｈ圣火三绝阵！
		for i = 15, 35 do
			lib.GetKey()
			NewDrawString(-1, -1, "圣火三绝阵", C_GOLD, CC.DefaultFont+i*2)
			ShowScreen()
			Cls()
			if i == 35 then
				lib.Delay(500)
			else
				lib.Delay(5)
			end
		end
	end

	--密道成昆战，我方集气全体为0
	if WAR.ZDDH == 237 then
		for a = 0, WAR.PersonNum - 1 do
			if WAR.Person[a]["我方"] == true then
				WAR.Person[a].Time = 0
			end
		end
	end

	--全真七子，天罡北斗阵
	if WAR.ZDDH == 73 then
		for i = 15, 35 do
			lib.GetKey()
			NewDrawString(-1, -1, "天罡北斗阵", C_GOLD, CC.DefaultFont+i*2)
			ShowScreen()
			Cls()
			if i == 35 then
				lib.Delay(500)
			else
				lib.Delay(5)
			end
		end
	end

	--组合动画显示
	if CC.CoupleDisplay == 1 then
		local function fightcombo()
			local combo = {}
			for i = 1, #CC.COMBO do
				combo[i] = {CC.COMBO[i][1], CC.COMBO[i][2], CC.COMBO[i][3],0}
			end
			for i = 0, WAR.PersonNum - 1 do
				local t = WAR.Person[i]["人物编号"]
				for j = 1, #combo do
					lib.GetKey()
					if match_ID(t, combo[j][1]) then
						for z = 0, WAR.PersonNum - 1 do
							local t2 = WAR.Person[z]["人物编号"]
							if match_ID(t2, combo[j][2]) and WAR.Person[i]["我方"] == WAR.Person[z]["我方"] then
								combo[j][4] = 1
								break
							end
						end
					end
				end
			end
			for i = 1, #combo do
				if combo[i][4] == 1 then
					local t1 = combo[i][1]
					local t2 = combo[i][2]
					for j = 0, 10 do
						lib.GetKey()
						local str = JY.Person[t1]["姓名"].."＆"..JY.Person[t2]["姓名"]
						local str2 = combo[i][3]
						Cls()
						DrawBox(150, CC.ScreenH / 3 + 30, CC.ScreenW - 150, CC.ScreenH / 3 * 2 - 20, C_BLACK)
						lib.LoadPNG(1, JY.Person[t1]["头像代号"]*2, CC.ScreenW / 4 - 80, CC.ScreenH / 2 - 35, 1)
						lib.LoadPNG(1, JY.Person[t2]["头像代号"]*2, CC.ScreenW / 4 + 50, CC.ScreenH / 2 - 35, 1)
						NewDrawString(CC.ScreenW / 2 * 3 - 170, CC.ScreenH + 120, str, C_ORANGE, 25)
						NewDrawString(CC.ScreenW / 2 * 3 - 170, -1, str2, C_GOLD, 50 + j)
						ShowScreen()
						lib.Delay(30)
					end
					lib.Delay(400)
				end
			end
		end
		fightcombo()
	end

	--四帮主之战，乔峰用铁掌
	if WAR.ZDDH == 83 then
		JY.Person[50]["武功1"] = 13
    end

	warStatus = 0
	buzhen()
	--Pre_Yungong()	--无酒不欢：战前运功

	--黄蓉奇门遁甲在此
	WarNewLand0()
	--WarFixBack()

	WAR.Delay = GetJiqi()
	local startt, endt = lib.GetTime()

  --战斗主循环
  while true do
	if JY.Restart == 1 then
		return false
	end
    WarDrawMap(0)
    WAR.ShowHead = 0
    DrawTimeBar()

    lib.GetKey()
    ShowScreen()
    if WAR.ZYHB == 1 then
		WAR.ZYHB = 2
    end

    local reget = false

    for p = 0, WAR.PersonNum - 1 do
		lib.GetKey()

		if WAR.Person[p]["死亡"] == false and WAR.Person[p].Time > 1000 then


        WarDrawMap(0)
        ShowScreen()
        local keypress = lib.GetKey()
        if WAR.AutoFight == 1 and (keypress == VK_SPACE or keypress == VK_RETURN) then
			WAR.AutoFight = 0
        end
        reget = true
        local id = WAR.Person[p]["人物编号"]


        --左右触发之后，不可移动
        if WAR.ZYHB == 2 then
			WAR.Person[p]["移动步数"] = 0
		--特效：不可移动
        elseif WAR.L_NOT_MOVE[WAR.Person[p]["人物编号"]] ~= nil and WAR.L_NOT_MOVE[WAR.Person[p]["人物编号"]] == 1 then
        	WAR.Person[p]["移动步数"] = 0
        	WAR.L_NOT_MOVE[WAR.Person[p]["人物编号"]] = nil
        else
        	--计算移动步数
			WAR.Person[p]["移动步数"] = getnewmove(p)
        end

        --[[最大移动步数10
        if WAR.Person[p]["移动步数"] > 10 then
			WAR.Person[p]["移动步数"] = 10
        end]]

        WAR.ShowHead = 0
        WarDrawMap(0)
        WAR.Effect = 0
        WAR.CurID = p
        WAR.Person[p].TimeAdd = 0
        local r = nil
        local pid = WAR.Person[WAR.CurID]["人物编号"]
        WAR.Defup[pid] = nil

		--段誉的指令，行动前恢复
        if match_ID(pid, 53) then
			WAR.TZ_DY = 0
        end

		--慕容复的指令，行动前恢复
        if match_ID(pid, 51) then
			WAR.TZ_MRF = 0
        end

		--重置黄蓉八卦位置
		if GetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 6) > 0 then
			WarNewLand0()
		end

		--阿青，行动前内伤中毒清0
	    if match_ID(pid, 604) then
			JY.Person[pid]["受伤程度"] = 0
			JY.Person[pid]["中毒程度"] = 0
	    end

		--阿九，行动开始前，60%几率降低敌方集气100点
		if match_ID(pid, 629) and JLSD(20,80,pid) then
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["死亡"] == false and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
					WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - 100
				end
			end
			DrawTimeBar2()
		end

		--先天调息，60%几率休息
		if Curr_NG(pid, 100) and math.random(10) < 7 then
			WarDrawMap(0); --不加这条则动画位置无法正常显示
			CurIDTXDH(WAR.CurID, 19,1,"先天调息",C_ORANGE);
			WAR.XTTX = 1
			War_RestMenu()
			WAR.XTTX = 0
		end

		--战三渡时，超过100时序，周芷若领悟左右
		if WAR.ZDDH == 253 and match_ID(pid, 631) and WAR.ZZRZY == 0 and 100 < WAR.SXTJ then
			say("１Ｌ＜这三人心意相通，如攻其一人，则其余两人立即回护，这样如何能够破阵？ｗ……若能分心二用，同时攻击两方，且他们如何应对＞Ｗ", 357, 0,"周芷若")  --对话
			if JY.Base["畅想"] == 631 then
				JY.Person[0]["左右互搏"] = 1
			else
				JY.Person[631]["左右互搏"] = 1
			end
			WAR.ZZRZY = 1
		end

		--混乱状态，行动前敌我随机
		--只剩一个敌人时不会进行随机
		if WAR.HLZT[pid] ~= nil then
			local EmenyNum = 0
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["死亡"] == false and WAR.Person[i]["我方"] == false then
					EmenyNum = EmenyNum + 1
				end
			end
			if EmenyNum > 1 then
				if math.random(2) == 1 then
					WAR.Person[p]["我方"] = true
				else
					WAR.Person[p]["我方"] = false
				end
			end
		end

		--行动时显示血条
		WAR.ShowHP = 1

		--无酒不欢：行动时，获取指令
		if WAR.HMZT[pid] ~= nil then			--昏迷状态
			WarDrawMap(0); --不加这条则动画位置无法正常显示
			CurIDTXDH(WAR.CurID, 94,1,"昏迷中",C_ORANGE)
			WAR.HMZT[pid] = nil
        elseif inteam(pid) and WAR.Person[p]["我方"] then
			if WAR.AutoFight == 0 then
				r = War_Manual()
			elseif JY.Person[pid]["禁用自动"] == 1 then
				r = War_Manual()
			else
				r = War_Auto()
			end
        else
			r = War_Auto()
        end

		if JY.Restart == 1 then
			return false
		end


        --如果发动左右互搏
        if WAR.ZYHB == 1 then
			for j = 0, WAR.PersonNum - 1 do
				WAR.Person[j].Time = WAR.Person[j].Time - 15
				if WAR.Person[j].Time > 990 then
					WAR.Person[j].Time = 990
				end
			end
			WAR.Person[p].Time = 1005
			if WAR.ZHB == 0 then	--周伯通的额外左右这里不再重复记录
				WAR.ZYYD = WAR.Person[p]["移动步数"]
			end
			WAR.ZYHBP = p

	        --一灯，避免被反死
	        if JY.Person[65]["生命"] <= 0 and WAR.WCY[65] == nil then
				JY.Person[65]["生命"] = 1
	        end

	        if JY.Base["畅想"] == 65 and JY.Person[0]["生命"] <= 0 and WAR.WCY[0] == nil then
				JY.Person[0]["生命"] = 1
	        end

			--王重阳
			if JY.Person[129]["生命"] <= 0 and WAR.CYZX[129] == nil then
				JY.Person[129]["生命"] = 1
			end

	        if JY.Base["畅想"] == 129 and JY.Person[0]["生命"] <= 0 and WAR.CYZX[0] == nil then
				JY.Person[0]["生命"] = 1
	        end

			--阎基偷钱
			if WAR.YJ > 0 then
				instruct_2(174, WAR.YJ)
				WAR.YJ = 0
			end
        else
	        if WAR.ZYHB == 2 then
				WAR.ZYHB = 0
	        end
			if WAR.Wait[id] == 1 then
				WAR.Wait[id] = 0
			else
	        	WAR.Person[p].Time = WAR.Person[p].Time - 1000
	        	if WAR.Person[p].Time < -500 then
	         		WAR.Person[p].Time = -500
	        	end
			end

			--罗汉伏魔功 每回合回复生命
			if PersonKF(id, 96) and JY.Person[id]["生命"] > 0 then
				local heal_amount;
				heal_amount = (JY.Person[id]["生命最大值"] - JY.Person[id]["生命"])/JY.Person[pid]["血量翻倍"]
				if Curr_NG(id, 96) then
					heal_amount = math.modf(heal_amount * 0.2)
				else
					heal_amount = math.modf(heal_amount * 0.1)
				end
				WAR.Person[WAR.CurID]["生命点数"] = AddPersonAttrib(id, "生命", heal_amount);
				Cls();
				War_Show_Count(WAR.CurID, "罗汉伏魔功恢复生命");
			end
			--回合结束消耗体力内力
			if inteam(id) then
				JY.Person[id]["体力"] = math.max(JY.Person[id]["体力"] - 1, 0)
			end
			NeiLiDamage(id, 100 - JY.Person[id]["体力"])

			if GetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 6) == 3 then
				local heal_amount = math.modf((JY.Person[id]["生命最大值"] - JY.Person[id]["生命"]) * 0.16)
				WAR.Person[WAR.CurID]["生命点数"] = AddPersonAttrib(id, "生命", heal_amount);
				Cls();
				War_Show_Count(WAR.CurID, "八卦逆位气血回复");
			end

			local NS = 5
			WAR.Person[WAR.CurID]["内伤点数"] = (WAR.Person[WAR.CurID]["内伤点数"] or 0) + AddPersonAttrib(id, "受伤程度", -NS)
			Cls();
			War_Show_Count(WAR.CurID, "内伤恢复");

	        --紫霞神功行动后，回复内力
			if PersonKF(id, 89) then
				local HN;
				if Curr_NG(id, 89) then
					HN = math.modf((JY.Person[id]["内力最大值"] - JY.Person[id]["内力"])*0.2)
				else
					HN = math.modf((JY.Person[id]["内力最大值"] - JY.Person[id]["内力"])*0.1)
				end
				WAR.Person[WAR.CurID]["内力点数"] = AddPersonAttrib(id, "内力", HN);
				Cls();
				War_Show_Count(WAR.CurID, "紫霞神功回复内力");
			end

	        --鳄皮护甲 每回合解毒
			if JY.Person[id]["防具"] == 61 and JY.Person[id]["中毒程度"] > 0 then
				local JD = 25 + 10 * (JY.Thing[61]["装备等级"]-1)
				if JY.Person[id]["中毒程度"] < JD then
					JD = JY.Person[id]["中毒程度"]
				end
				WAR.Person[WAR.CurID]["解毒点数"] = -AddPersonAttrib(id, "中毒程度", -JD)
				Cls();
				War_Show_Count(WAR.CurID, "鳄皮护甲生化解毒");
			end

			--蛤蟆蓄力
			if WAR.HMGXL[id] == 1 then
				WAR.HMGXL[id] = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 300
			end

			--林平之根据伤害回气
			if match_ID_awakened(id, 36, 1) and WAR.LPZ > 0 then
				WAR.Person[p].Time = WAR.Person[p].Time + WAR.LPZ
				WAR.LPZ = 0
			end

			--虚竹福泽加护
	        if match_ID(id, 49) and WAR.XZZ == 1 then
				WAR.XZZ = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 200
	        end

			--张三丰万法自然
	        if match_ID(id, 5) and WAR.ZSF == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.ZSF = 0
	        end

			--封不平狂风快剑
			if match_ID(id, 142) and WAR.KFKJ == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 100
				WAR.KFKJ = 0
			end

			--九剑真传，荡剑式，回气200
			if WAR.JJDJ == 1 and id == 0 then
				WAR.JJDJ = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 200
			end

			--主运飞天回气200
			if Curr_QG(id,145) then
				WAR.Person[p].Time = WAR.Person[p].Time + 200
			end

			--运轻功
			if WAR.YQG == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.YQG = 0
			end

	        --朱九真，随机得到食材
	        if match_ID(id, 81) and WAR.ZJZ == 0 and math.random(100)>60 then
				instruct_2(210, 10)
				WAR.ZJZ = 1
	        end

	        --一灯，避免被反死
	        if JY.Person[65]["生命"] <= 0 and WAR.WCY[65] == nil then
				JY.Person[65]["生命"] = 1
	        end

	        if JY.Base["畅想"] == 65 and JY.Person[0]["生命"] <= 0 and WAR.WCY[0] == nil then
				JY.Person[0]["生命"] = 1
	        end

			--王重阳
			if JY.Person[129]["生命"] <= 0 and WAR.CYZX[129] == nil then
				JY.Person[129]["生命"] = 1
			end

	        if JY.Base["畅想"] == 129 and JY.Person[0]["生命"] <= 0 and WAR.CYZX[0] == nil then
				JY.Person[0]["生命"] = 1
	        end

	        --主角，其疾如风，集气500
	        if WAR.FLHS1 == 1 and id == 0 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.FLHS1 = 0
	        end

	        --杨过，行动后集气初始位置额外增加
	        --生命少过二分之一时每少100增加行动后集气位置加100
	        if match_ID(id, 58) and JY.Person[id]["生命"] < JY.Person[id]["生命最大值"]/2 then
	        	WAR.Person[p].Time = WAR.Person[p].Time + math.floor(JY.Person[id]["生命最大值"]/2/JY.Person[id]["血量翻倍"] - JY.Person[id]["生命"]/JY.Person[id]["血量翻倍"]);
	        end

			--阎基偷钱
	        if WAR.YJ > 0 then
				instruct_2(174, WAR.YJ)
				WAR.YJ = 0
	        end

	        --盲目状态恢复
			--[[
	        if WAR.KHCM[pid] == 2 then
				WAR.KHCM[pid] = 0
				Cls()
				DrawStrBox(-1, -1, "盲目状态恢复", C_ORANGE, CC.DefaultFont)
				ShowScreen()
				lib.Delay(500)
	        end]]

			--宋远桥使用太极拳或太极剑攻击后自动进入防御状态
			if match_ID(id, 171) and WAR.WDRX == 1 then
				War_DefupMenu()
				WAR.WDRX = 0
			end

	        if WAR.Actup[id] ~= nil then
				if WAR.ZXXS[id] ~= nil then				--紫霞蓄势状态，蓄力不减
					WAR.ZXXS[id] = WAR.ZXXS[id] - 1
					if WAR.ZXXS[id] == 0 then
						WAR.ZXXS[id] = nil
					end
				else
					WAR.Actup[id] = WAR.Actup[id] - 1	--蓄力，行动一次减1
				end
	        end

	        if WAR.Actup[id] == 0 then
				WAR.Actup[id] = nil
	        end

			if WAR.SLSX[pid] ~= nil then
				WAR.SLSX[pid] = WAR.SLSX[pid] - 1
				if WAR.SLSX[pid] == 0 then
					WAR.SLSX[pid] = nil
				end
			end

			--行动后漏出破绽
			WAR.Weakspot[id] = 0

			--辟邪冷却时间恢复
			if WAR.BXLQ[id] then
				for i = 1, 6 do
					WAR.BXLQ[id][i] = WAR.BXLQ[id][i] - 1
					if WAR.BXLQ[id][i] < 0 then
						WAR.BXLQ[id][i] = 0
					end
				end
			end

			--乔峰的铁掌名字恢复
	        JY.Wugong[13]["名称"] = "铁掌"

	        --周伯通，每行动一次，攻击时伤害一+10%
	        if match_ID(id, 64) then
				WAR.ZBT = WAR.ZBT + 1
	        end

			--王重阳北斗七闪状态减少
			if match_ID(id, 129) and WAR.CYZX[id] ~= nil and WAR.BDQS > 0 then
				WAR.BDQS = WAR.BDQS - 1
				if WAR.BDQS == 0 then
					CurIDTXDH(WAR.CurID, 126,1,"北斗七闪·收招",C_GOLD);
				end
			end

			--暴怒恢复
	        if WAR.LQZ[id] == 100 then
				--王重阳北斗七闪状态行动后暴怒不减
				if not (match_ID(id, 129) and WAR.CYZX[id] ~= nil and WAR.BDQS > 0) then
					WAR.LQZ[id] = 0
				end
	        end

			--刀主大招，行动后恢复怒气
			if id == 0 and JY.Base["标准"] == 4 and WAR.YZHYZ > 0 then
				WAR.LQZ[id] = limitX((WAR.LQZ[id] or 0) + WAR.YZHYZ, 0, 100)
				WAR.YZHYZ = 0
				if WAR.LQZ[id] ~= nil and WAR.LQZ[id] == 100 then
					CurIDTXDH(WAR.CurID, 6, 1, "怒气爆发")
				end
			end

	        --杨过 吼  龙儿~~
	        if WAR.XK == 1 then
				for j = 0, WAR.PersonNum - 1 do
					if WAR.Person[j]["人物编号"] == 58 and 0 < JY.Person[WAR.Person[j]["人物编号"]]["生命"] and WAR.Person[j]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
						WAR.Person[j].Time = 980
						say("１Ｒ龙儿－－－－－－！Ｈ５啊－－－－４－－－－３－－－－２－－－－１－－－－－－－－！！！", 58,0)
						WAR.XK = 2
					end
				end
	        end

	        --发动 难知如阴
	        if WAR.FLHS5 == 1 then
				local z = WAR.CurID
				for j = 0, WAR.PersonNum - 1 do
					if WAR.Person[j]["人物编号"] == 0 and 0 < JY.Person[0]["生命"] then
						WAR.FLHS5 = 2
						WAR.CurID = j
					end
				end
				if WAR.FLHS5 == 2 and WAR.AutoFight == 0 then
					WAR.Person[WAR.CurID]["移动步数"] = 6
					War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
					local x, y = nil, nil
					while 1 do
						if JY.Restart == 1 then
							break
						end
						x, y = War_SelectMove()
						if x ~= nil then
							WAR.ShowHead = 0
							War_MovePerson(x, y)
							break;
						end
					end
				end
				WAR.FLHS5 = 0
				WAR.CurID = z
	        end

	        --圣火神功 攻击后可移动
	        if (0 < WAR.Person[p]["移动步数"] or 0 < WAR.ZYYD) and WAR.Person[p]["我方"] == true and inteam(id) and WAR.AutoFight == 0 and PersonKF(id, 93) and 0 < JY.Person[id]["生命"] then
				if 0 < WAR.ZYYD then
					WAR.Person[p]["移动步数"] = WAR.ZYYD
					War_CalMoveStep(p, WAR.ZYYD, 0)
				else
					War_CalMoveStep(p, WAR.Person[p]["移动步数"], 0)
				end
				local x, y = nil, nil
				while 1 do
					if JY.Restart == 1 then
						break
					end
					x, y = War_SelectMove()
					if x ~= nil then
						WAR.ShowHead = 0
						War_MovePerson(x, y)
						break;
					end
				end
	        end

			--无酒不欢：无论是否触发了圣火再移动，这个变量都应该在这一步清除，否则会影响到下一个人的圣火判定
			--触发周伯通左右补偿不清除
			if WAR.ZHB == 0 then
				WAR.ZYYD = 0
			end

			--周伯通的追加互搏判定
			if WAR.ZHB == 1 then
				WAR.ZHB = 0
			end

			--阿凡提 攻击后可移动
			if match_ID(id,606) and WAR.Person[p]["我方"] == true and WAR.AutoFight == 0 and 0 < JY.Person[id]["生命"] then
				WAR.Person[p]["移动步数"] = 10
				War_CalMoveStep(p, WAR.Person[p]["移动步数"], 0)
				local x, y = nil, nil
				while 1 do
					if JY.Restart == 1 then
						break
					end
					x, y = War_SelectMove()
					if x ~= nil then
						WAR.ShowHead = 0
						War_MovePerson(x, y)
						break;
					end
				end
			end

	        --雪山上杀血刀老祖后，恢复我方人物
	        if WAR.ZDDH == 7 then
				for x = 0, WAR.PersonNum - 1 do
					if WAR.Person[x]["人物编号"] == 97 and JY.Person[97]["生命"] <= 0 then
						for xx = 0, WAR.PersonNum - 1 do
							if WAR.Person[xx]["人物编号"] ~= 97 then
								WAR.Person[xx]["我方"] = true
							end
						end
					end
				end
	        end

			--无酒不欢：、、、
	        if WAR.ZDDH == 54 and lib.GetWarMap(11, 36, 1) == 2 and inteam(WAR.Person[p]["人物编号"]) and WAR.Person[p]["坐标X"] == 12 and WAR.Person[p]["坐标Y"] == 36 then
				lib.SetWarMap(11, 36, 1, 5420)
				WarDrawMap(0)
				say("AA")
				say("OHMYGO", 27)
				lib.SetWarMap(11, 36, 1, 0)
	        end

			--九剑破招减少集气
			if WAR.JJPZ[id] == 1 then
				WAR.Person[p].Time = -200
				WAR.JJPZ[id] = nil
			end

			--太空卸劲减少集气
			if WAR.TKJQ[id] == 1 then
				WAR.Person[p].Time = -120
				WAR.TKJQ[id] = nil
			end

			--[[行动后回气的效果上限600点
	        if 600 < WAR.Person[p].Time then
				WAR.Person[p].Time = 600
	        end]]

			--无酒不欢：袁承志，碧血长风，杀人后再动
	        if match_ID(id, 54) and WAR.BXCF == 1 and War_isEnd() == 0 then
				for i = 12, 24 do
					NewDrawString(-1, -1, "碧血长风", C_RED, 25 + i)
					ShowScreen()
					if i == 24 then
						Cls()
						NewDrawString(-1, -1, "碧血长风", C_RED, 25 + i)
						ShowScreen()
						lib.Delay(500)
					else
						lib.Delay(1)
					end
				end
				for j = 0, WAR.PersonNum - 1 do
					WAR.Person[j].Time = WAR.Person[j].Time - 10
					if 995 < WAR.Person[j].Time then
						WAR.Person[j].Time = 995
					end
				end
				WAR.Person[WAR.CurID].Time = 1005

				WAR.BXCF = 0
	        end

	        --资质越高发动几率越高
	        local pz = math.modf(JY.Person[0]["资质"] / 10)
	        --主角医生大招，直接再次行动
	        if id == 0 and JY.Base["标准"] == 8 and JY.Person[pid]["六如觉醒"] > 0 then
	        	if 50 < JY.Person[0]["体力"] then
					if WAR.HTSS == 0 and JLSD(25, 60 + pz, 0) and 0 < JY.Person[0]["武功9"] then
						CurIDTXDH(WAR.CurID, 91, 1)
						Cls()

						ShowScreen()
						lib.Delay(40)
						for i = 12, 24 do
							NewDrawString(-1, -1, ZJTF[8] .. TFSSJ[8], C_GOLD, 25 + i)
							ShowScreen()
							if i == 24 then
								Cls()
								NewDrawString(-1, -1, ZJTF[8] .. TFSSJ[8], C_GOLD, 25 + i)
								ShowScreen()
								lib.Delay(500)
							else
								lib.Delay(1)
							end
						end
						for j = 0, WAR.PersonNum - 1 do
							WAR.Person[j].Time = WAR.Person[j].Time - 10
							if 995 < WAR.Person[j].Time then
								WAR.Person[j].Time = 995
							end
						end
						WAR.Person[WAR.CurID].Time = 1005
						JY.Person[0]["体力"] = JY.Person[0]["体力"] - 10
						--有低概率再次发动
						if JLSD(45, 50, 0) then
							WAR.HTSS = 0
						else
							WAR.HTSS = 1
						end
					end
				else
					WAR.HTSS = 0
				end
	        end

	        --成昆密道 100时序就跑
	        if WAR.ZDDH == 237 and 100 < WAR.SXTJ then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["我方"] == false then
						WAR.Person[i]["死亡"] = true
					end
				end
				say("１Ｌ＜嗯，没功夫跟这"..JY.Person[0]["外号2"].."纠缠了＞Ｗ哈哈哈，"..JY.Person[0]["外号2"].."，算你走运！老夫还有要事待办，这次就放你一马！", 18,0)
	        end

	      	 --冰糖恋：正十五大20时序胜利
	        if WAR.ZDDH == 134 and 20 < WAR.SXTJ and GetS(87,31,32,5) == 1 then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["我方"] == false then
						WAR.Person[i]["死亡"] = true
					end
				end
				TalkEx("恭喜"..JY.Person[0]["外号"].."挺过20时序，成功过关。",269,0);
	        end

			--冰糖恋：邪十五大20时序胜利
	        if WAR.ZDDH == 133 and 20 < WAR.SXTJ and GetS(87,31,31,5) == 1 then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["我方"] == false then
						WAR.Person[i]["死亡"] = true
					end
				end
				TalkEx("恭喜"..JY.Person[0]["外号"].."挺过20时序，成功过关。",269,0);
	        end


	        --旧版华山论剑，敌我随机变换
	        if WAR.ZDDH == 238 then
	        	local life = 0
	        	WAR.NO1 = 114;
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["死亡"] == false and 0 < JY.Person[WAR.Person[i]["人物编号"]]["生命"] then
						life = life + 1
						if WAR.NO1 >= WAR.Person[i]["人物编号"] then
							WAR.NO1 = WAR.Person[i]["人物编号"]
						end
					end
				end

				if 1 < life then
					local m, n = 0, 0
					while true do			--防止全部随机到已方
						if m >= 1 and n >= 1 then
							break;
						else
							m = 0;
							n = 0;
						end

						for i = 0, WAR.PersonNum - 1 do
							if WAR.Person[i]["死亡"] == false and 0 < JY.Person[WAR.Person[i]["人物编号"]]["生命"] then
								if WAR.Person[i]["人物编号"] == 0 then
									WAR.Person[i]["我方"] = true
									m = m + 1
								elseif math.random(2) == 1 then
									WAR.Person[i]["我方"] = true
									m = m + 1
								else
									WAR.Person[i]["我方"] = false
									n = n + 1
								end
							end
						end
					end
				end
	        end
	    end
	end

		warStatus = War_isEnd()   --战斗是否结束？   0继续，1赢，2输
		if 0 < warStatus then
			break;
		end
		CleanMemory()
    end
    if 0 < warStatus then
     	break;
    end
    WarPersonSort(1)
    WAR.Delay = GetJiqi()
    startt = lib.GetTime()
    collectgarbage("step", 0)
  end
  local r = nil
  WAR.ShowHead = 0

	--战斗结束后的奖励
	if WAR.ZDDH == 238 then
		PlayMIDI(111)
		PlayWavAtk(41)
		DrawStrBoxWaitKey("论剑结束", C_WHITE, CC.DefaultFont)
		DrawStrBoxWaitKey("武功天下第一者：" .. JY.Person[WAR.NO1]["姓名"], C_RED, CC.DefaultFont)
		if WAR.NO1 == 0 then
		  r = true
		else
		  r = false
		end
	--战斗胜利
	elseif warStatus == 1 then
		PlayMIDI(111)
		PlayWavAtk(41)
		--DrawStrBoxWaitKey("战斗胜利", C_WHITE, CC.DefaultFont)
		lib.LoadPNG(1, 998 * 2 , 295, 295, 1)
		ShowScreen();
		WaitKey();
		if WAR.ZDDH == 76 then
			DrawStrBoxWaitKey("特殊奖励：千年灵芝两枚", C_GOLD, CC.DefaultFont)
			instruct_32(14, 2)
		elseif WAR.ZDDH == 15 or WAR.ZDDH == 80 then
			DrawStrBoxWaitKey("特殊奖励：主角五系兵器值提升十点", C_RED, CC.DefaultFont,nil,C_GOLD)
			AddPersonAttrib(0, "拳掌功夫", 10)
			AddPersonAttrib(0, "指法技巧", 10)
			AddPersonAttrib(0, "御剑能力", 10)
			AddPersonAttrib(0, "耍刀技巧", 10)
			AddPersonAttrib(0, "特殊兵器", 10)
		elseif WAR.ZDDH == 100 then
			DrawStrBoxWaitKey("特殊奖励：获得天王保命丹两颗", C_GOLD, CC.DefaultFont)
			instruct_32(8, 2)
		elseif WAR.ZDDH == 172 then
			DrawStrBoxWaitKey("特殊奖励：获得蛤蟆功秘籍一本", C_GOLD, CC.DefaultFont)
			instruct_32(73, 1)
		elseif WAR.ZDDH == 173 then
			DrawStrBoxWaitKey("特殊奖励：获得天山雪莲两枚", C_GOLD, CC.DefaultFont)
			instruct_32(17, 2)
		elseif WAR.ZDDH == 188 then
			local hqjl = JYMsgBox("特殊奖励", "你完成了奖励战**请选择一项兵器值进行提高", {"拳法","指法","剑法","刀法","奇门"}, 5, 69)
			if hqjl == 1 then
				AddPersonAttrib(0, "拳掌功夫", 10)
				DrawStrBoxWaitKey("你的拳掌功夫提高了十点",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --清屏
			elseif hqjl == 2 then
				AddPersonAttrib(0, "指法技巧", 10)
				DrawStrBoxWaitKey("你的指法技巧提高了十点",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --清屏
			elseif hqjl == 3 then
				AddPersonAttrib(0, "御剑能力", 10)
				DrawStrBoxWaitKey("你的御剑能力提高了十点",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --清屏
			elseif hqjl == 4 then
				AddPersonAttrib(0, "耍刀技巧", 10)
				DrawStrBoxWaitKey("你的耍刀技巧提高了十点",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --清屏
			elseif hqjl == 5 then
				AddPersonAttrib(0, "特殊兵器", 10)
				DrawStrBoxWaitKey("你的特殊兵器提高了十点",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --清屏
			end
		elseif WAR.ZDDH == 211 then
			DrawStrBoxWaitKey("特殊奖励：主角防御力和轻功各提升十点", C_GOLD, CC.DefaultFont)
			AddPersonAttrib(0, "防御力", 10)
			AddPersonAttrib(0, "轻功", 10)
		elseif WAR.ZDDH == 86 then
			instruct_2(66, 1)
		elseif WAR.ZDDH == 4 then
			if JY.Person[0]["实战"] < 500 then
				QZXS(string.format("%s 实战增加%s点",JY.Person[0]["姓名"],30));
				JY.Person[0]["实战"] = JY.Person[0]["实战"] + 30
				if JY.Person[0]["实战"] > 500 then
					JY.Person[0]["实战"] = 500
				end
			end
		elseif WAR.ZDDH == 77 then
			if JY.Person[0]["实战"] < 500 then
				QZXS(string.format("%s 实战增加%s点",JY.Person[0]["姓名"],20));
				JY.Person[0]["实战"] = JY.Person[0]["实战"] + 20
				if JY.Person[0]["实战"] > 500 then
					JY.Person[0]["实战"] = 500
				end
			end
		elseif WAR.ZDDH > 42 and  WAR.ZDDH < 47 then
			if JY.Person[0]["实战"] < 500 then
				QZXS(string.format("%s 实战增加%s点",JY.Person[0]["姓名"],10));
				JY.Person[0]["实战"] = JY.Person[0]["实战"] + 10
				if JY.Person[0]["实战"] > 500 then
					JY.Person[0]["实战"] = 500
				end
			end
		elseif WAR.ZDDH == 161 then
			if JY.Person[0]["实战"] < 500 then
				QZXS(string.format("%s 实战增加%s点",JY.Person[0]["姓名"],30));
				JY.Person[0]["实战"] = JY.Person[0]["实战"] + 30
				if JY.Person[0]["实战"] > 500 then
					JY.Person[0]["实战"] = 500
				end
			end
		--战胜海大富
		elseif WAR.ZDDH == 259 then
			DrawStrBoxWaitKey("特殊奖励：获得化骨绵掌秘籍一本", C_GOLD, CC.DefaultFont)
			instruct_32(275,1)
		--新论剑奖励 根据敌人不同奖励不同
		elseif WAR.ZDDH == 266 then
			--老周
			if GetS(85, 40, 38, 4) == 64 then
				if JY.Person[0]["左右互搏"] == 1 then
					DrawStrBoxWaitKey("特殊奖励：你的左右互搏几率永久提高了20% ", LimeGreen, 36,nil, C_GOLD)
					JY.Person[64]["论剑奖励"] = 1
				else
					DrawStrBoxWaitKey("你似乎错过了一项奖励……", LimeGreen, 36,nil, C_GOLD)
				end
			--老王
			elseif GetS(85, 40, 38, 4) == 129 then
				DrawStrBoxWaitKey("特殊奖励：你的暴击率永久提高了70% ", LimeGreen, 36,nil, C_GOLD)
				JY.Person[129]["论剑奖励"] = 1
			--林朝英
			elseif GetS(85, 40, 38, 4) == 605 then
				DrawStrBoxWaitKey("特殊奖励：你的连击率永久提高了50% ", LimeGreen, 36,nil, C_GOLD)
				JY.Person[605]["论剑奖励"] = 1
			--阿青
			elseif GetS(85, 40, 38, 4) == 604 then
				DrawStrBoxWaitKey("特殊奖励：你的气防永久提高了700点", LimeGreen, 36,nil, C_GOLD)
				JY.Person[604]["论剑奖励"] = 1
				--instruct_32(278,1)
			--风清扬
			elseif GetS(85, 40, 38, 4) == 140 then
				if PersonKF(0, 47) then
					DrawStrBoxWaitKey("特殊奖励：你获得了独孤九剑的真传", LimeGreen, 36,nil, C_GOLD)
					JY.Person[592]["论剑奖励"] = 1
				else
					DrawStrBoxWaitKey("你似乎错过了一项奖励……", LimeGreen, 36,nil, C_GOLD)
				end
			--东方不败
			elseif GetS(85, 40, 38, 4) == 27 then
				DrawStrBoxWaitKey("特殊奖励：你的集气速度永久提高了8点", LimeGreen, 36,nil, C_GOLD)
				JY.Person[27]["论剑奖励"] = 1
			--扫地
			elseif GetS(85, 40, 38, 4) == 114 then
				DrawStrBoxWaitKey("特殊奖励：你的武学常识提高了100点", LimeGreen, 36,nil, C_GOLD)
				JY.Person[114]["论剑奖励"] = 1
				AddPersonAttrib(0, "武学常识", 100)
			--三丰
			elseif GetS(85, 40, 38, 4) == 5 then
				DrawStrBoxWaitKey("特殊奖励：你的攻防轻和五系兵器值全面提高了", LimeGreen, 36,nil, C_GOLD)
				JY.Person[5]["论剑奖励"] = 1
				AddPersonAttrib(0, "攻击力", 30)
				AddPersonAttrib(0, "防御力", 30)
				AddPersonAttrib(0, "轻功", 30)
				AddPersonAttrib(0, "拳掌功夫", 20)
				AddPersonAttrib(0, "指法技巧", 20)
				AddPersonAttrib(0, "御剑能力", 20)
				AddPersonAttrib(0, "耍刀技巧", 20)
				AddPersonAttrib(0, "特殊兵器", 20)
			--阿凡提
			elseif GetS(85, 40, 38, 4) == 606 then
				DrawStrBoxWaitKey("特殊奖励：你获得了绝对先手的能力", LimeGreen, 36,nil, C_GOLD)
				JY.Person[606]["论剑奖励"] = 1
			end
		end
		--赵半山战斗胜利获得暗器
		if JY.Base["畅想"] == 153 and WAR.ZDDH ~= 226 then
			local anqi = math.random(28,35)
			local num = math.random(5)
			instruct_2(anqi,num)
		end
		r = true
	--战斗失败
	elseif warStatus == 2 then
		--DrawStrBoxWaitKey("战斗失败", C_WHITE, CC.DefaultFont)
		lib.LoadPNG(1, 999 * 2 , 295, 295, 1)
		ShowScreen();
		WaitKey();
		r = false
	end

	War_EndPersonData(isexp, warStatus)
	lib.ShowSlow(20, 1)
	if 0 <= JY.Scene[JY.SubScene]["进门音乐"] then
		PlayMIDI(JY.Scene[JY.SubScene]["进门音乐"])
	else
		PlayMIDI(0)
	end
	CleanMemory()
	lib.PicInit()

	--战斗结束，重新加载场景贴图
	lib.PicLoadFile(CC.SMAPPicFile[1], CC.SMAPPicFile[2], 0)	--子场景贴图，内存区域0
	lib.LoadPNGPath(CC.HeadPath, 1, CC.HeadNum, limitX(CC.ScreenW/936*100,0,100))	--人物头像，内存区域1
	lib.PicLoadFile(CC.ThingPicFile[1], CC.ThingPicFile[2], 2, 100, 100)	--物品贴图，内存区域2
	JY.Status = GAME_SMAP
	return r
end

--山洞妹妹，布阵
function buzhen()
	if not inteam(92) then
		return
	end
	if WAR.ZDDH == 226 then
		return
	end
	local line = "要布置阵型吗？";
	local tiles = 2;
	if (WAR.ZDDH == 133 or WAR.ZDDH == 134) and WAR.MCRS == 1 then
		if JY.Person[0]["性别"] == 0 then
			line = "哥哥你真勇敢，一个人挑战十五大高手，请千万小心。"
		else
			line = "姐姐你真勇敢，一个人挑战十五大高手，请千万小心。"
		end
		tiles = 4
	end
	say(line, 384,0,JY.Person[92]["姓名"])
	if not DrawStrBoxYesNo(-1, -1, "要布置阵型吗？", C_WHITE, CC.DefaultFont) then
		return
	end
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["我方"] then
			WAR.CurID = i
			WAR.ShowHead = 1
			--布阵统一为2格
			War_CalMoveStep(WAR.CurID, tiles, 0)
			local x, y = nil, nil
			while true do
				if JY.Restart == 1 then
					break
				end
				x, y = War_SelectMove()
				if x ~= nil then
					WAR.ShowHead = 0
					War_MovePerson(x, y)
					break;
				end
			end
		end
	end
end

--无酒不欢：战前运功
function Pre_Yungong()
	if WAR.ZDDH == 226 then
		return
	end
	if true then
		return
	end
	local id, x1, y1;
	for j = 0, WAR.PersonNum - 1 do
		if WAR.Person[j]["人物编号"] == 0 then
			id, x1, y1 = j, WAR.Person[j]["坐标X"], WAR.Person[j]["坐标Y"]
			break
		end
	end
	if x1 == nil then
		return
	end
	local s = WAR.CurID
	local r = JYMsgBox("战前运功", "战前强行运功是有额外代价的*要继续吗？", {"否","是"}, 2, WAR.tmp[5000+id])
	if r == 2 then
		local menu={};
		for i=1,CC.Kungfunum do
			menu[i]={JY.Wugong[JY.Person[0]["武功" .. i]]["名称"],nil,0};
			if JY.Wugong[JY.Person[0]["武功" .. i]]["武功类型"] == 6 then
				menu[i][3]=1;
			end
			--天罡不能运三大
			if 0 == 0 and JY.Base["标准"] == 6 and (JY.Person[0]["武功" .. i] == 106 or JY.Person[0]["武功" .. i] == 107 or JY.Person[0]["武功" .. i] == 108) then
				menu[i][3]=0;
			end
		end
		local main_neigong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
		if main_neigong ~= nil and main_neigong > 0 then
			WAR.CurID = id
			CleanWarMap(4, 0)
			SetWarMap(x1, y1, 4, 1)
			War_ShowFight(0, 0, 0, 0, 0, 0, 9)
			AddPersonAttrib(0, "内力", -500);
			AddPersonAttrib(0, "体力", -10);
			JY.Person[0]["主运内功"] = JY.Person[0]["武功" .. main_neigong]
			WAR.CurID = s
		end
	end
end

--无酒不欢：在自身位置播放动画的函数
function CurIDTXDH(id, eft, order, str, strColor, endFrame)
	--增加文字颜色控制
	if strColor == nil then
		strColor = C_GOLD
	end
	--增加强制结束帧
	if endFrame == nil then
		endFrame = CC.Effect[eft]
	end
	local x0, y0 = WAR.Person[id]["坐标X"], WAR.Person[id]["坐标Y"]
	local hb = GetS(JY.SubScene, x0, y0, 4)
	local starteft = 0

	for i = 0, eft - 1 do
		starteft = starteft + CC.Effect[i]
	end

	local px = 0
	local py = 0

	--狮王咆哮动画位置
	if eft == 118 then
		py = CC.YScale * 4
	end

	--玉石俱焚动画位置
	if eft == 124 then
		py = CC.YScale * 3
	end

	--倾国动画位置
	if eft == 149 then
		py = CC.YScale * 11
	end

	--喵姐的免疫攻击动画位置
	if eft == 135 then
		py = CC.YScale * 2
	end

	local ssid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)
	for ii = 1, endFrame, order do
		lib.GetKey()
		lib.PicLoadCache(3, (starteft + ii) * 2, CC.ScreenW / 2, CC.ScreenH / 2 - hb + py, 2, 192)
		if str ~= nil then
			DrawString(-1, CC.ScreenH / 2 - hb, str, strColor, CC.DefaultFont)
		end
		ShowScreen()
		lib.Delay(CC.BattleDelay)
		lib.LoadSur(ssid, 0, 0)
	end
	lib.FreeSur(ssid)
	Cls()
end


function WE_xy(x, y, id)
  if id ~= nil then
    War_CalMoveStep(id, 128, 0)
  else
    CleanWarMap(3, 0)
  end
  if GetWarMap(x, y, 3) ~= 255 and War_CanMoveXY(x, y, 0) then
    return x, y
  else
    for s = 1, 128 do
      for i = 1, s do
        local j = s - i
        if x + i < 63 and y + j < 63 and GetWarMap(x + i, y + j, 3) ~= 255 and War_CanMoveXY(x + i, y + j, 0) then
          return x + i, y + j
        end
        if x + j < 63 and y - i > 0 and GetWarMap(x + j, y - i, 3) ~= 255 and War_CanMoveXY(x + j, y - i, 0) then
          return x + j, y - i
        end
        if x - i > 0 and y - j > 0 and GetWarMap(x - i, y - j, 3) ~= 255 and War_CanMoveXY(x - i, y - j, 0) then
          return x - i, y - j
        end
        if x - j > 0 and y + i < 63 and GetWarMap(x - j, y + i, 3) ~= 255 and War_CanMoveXY(x - j, y + i, 0) then
          return x - j, y + i
        end
      end
    end
  end
  for s = 1, 128 do
    for i = 1, s do
      local j = s - i
      if x + i < 63 and y + j < 63 and War_CanMoveXY(x + i, y + j, 0) then
        return x + i, y + j
      end
      if x + j < 63 and y - i > 0 and War_CanMoveXY(x + j, y - i, 0) then
        return x + j, y - i
      end
      if x - i > 0 and y - j > 0 and War_CanMoveXY(x - i, y - j, 0) then
        return x - i, y - j
      end
      if x - j > 0 and y + i < 63 and War_CanMoveXY(x - j, y + i, 0) then
        return x - j, y + i
      end
    end
  end
  return x, y
end

--计算暗器伤害
function War_AnqiHurt(pid, emenyid, thingid, emeny)
	local num = nil
	local dam = nil
	if JY.Person[emenyid]["受伤程度"] == 0 then
		num = JY.Thing[thingid]["加生命"] / 2 - Rnd(3)
	elseif JY.Person[emenyid]["受伤程度"] <= 33 then
		num = math.modf(JY.Thing[thingid]["加生命"] *2 / 3) - Rnd(3)
	elseif JY.Person[emenyid]["受伤程度"] <= 66 then
		num = JY.Thing[thingid]["加生命"] - Rnd(3)
	else
		num = math.modf(JY.Thing[thingid]["加生命"] *4 / 3) - Rnd(3)
	end

	num = math.modf(num - JY.Person[pid]["暗器技巧"]/4)
	WAR.Person[emeny]["内伤点数"] = AddPersonAttrib(emenyid, "受伤程度", math.modf(-num / 6))
	dam = num * WAR.AQBS
	local r = AddPersonAttrib(emenyid, "生命", math.modf(dam))
	if (emenyid == 129 or emenyid == 65) and JY.Person[emenyid]["生命"] <= 0 then
		JY.Person[emenyid]["生命"] = 1
	end
	if JY.Person[emenyid]["生命"] <= 0 then
		WAR.Person[WAR.CurID]["经验"] = WAR.Person[WAR.CurID]["经验"] + JY.Person[emenyid]["等级"] * 5
	end
	if JY.Thing[thingid]["加中毒解毒"] > 0 then
		num = math.modf(JY.Thing[thingid]["加中毒解毒"] + JY.Person[pid]["暗器技巧"] / 4)
		num = num - JY.Person[emenyid]["抗毒能力"]
		num = limitX(num, 0, CC.PersonAttribMax["用毒能力"])
		WAR.Person[emeny]["中毒点数"] = AddPersonAttrib(emenyid, "中毒程度", num)
	end
	--沉睡状态的敌人会醒来
	if WAR.CSZT[emenyid] ~= nil then
		WAR.CSZT[emenyid] = nil
	end
	return r
end

--自动医疗
function War_AutoDoctor()
  local x1 = WAR.Person[WAR.CurID]["坐标X"]
  local y1 = WAR.Person[WAR.CurID]["坐标Y"]
  War_ExecuteMenu_Sub(x1, y1, 3, -1)
end

--自动吃药
--flag=2 生命，3内力；4体力  6 解毒
function War_AutoEatDrug(flag)
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local life = JY.Person[pid]["生命"]
	local maxlife = JY.Person[pid]["生命最大值"]
	local selectid = nil
	local minvalue = math.huge
	local shouldadd, maxattrib, str = nil, nil, nil
	if flag == 2 then
		maxattrib = JY.Person[pid]["生命最大值"]
		shouldadd = maxattrib - JY.Person[pid]["生命"]
		str = "加生命"
	elseif flag == 3 then
		maxattrib = JY.Person[pid]["内力最大值"]
		shouldadd = maxattrib - JY.Person[pid]["内力"]
		str = "加内力"
	elseif flag == 4 then
		maxattrib = CC.PersonAttribMax["体力"]
		shouldadd = maxattrib - JY.Person[pid]["体力"]
		str = "加体力"
	elseif flag == 6 then
		maxattrib = CC.PersonAttribMax["中毒程度"]
		shouldadd = JY.Person[pid]["中毒程度"]
		str = "加中毒解毒"
	else
		return
	end
	local function Get_Add(thingid)
		if flag == 6 then
		  return -JY.Thing[thingid][str] / 2
		else
		  return JY.Thing[thingid][str]
		end
	end

	--在队
	if inteam(pid) and WAR.Person[WAR.CurID]["我方"] == true then
		local extra = 0
		for i = 1, CC.MyThingNum do
			local thingid = JY.Base["物品" .. i]
			if thingid >= 0 then
				local add = Get_Add(thingid)
				if JY.Thing[thingid]["类型"] == 3 and add > 0 then
					local v = shouldadd - add
					if v < 0 then
						extra = 1
					elseif v < minvalue then
						minvalue = v
						selectid = thingid
					end
				end
			end
		end
		if extra == 1 then
			minvalue = math.huge
			for i = 1, CC.MyThingNum do
				local thingid = JY.Base["物品" .. i]
				if thingid >= 0 then
					local add = Get_Add(thingid)
					if JY.Thing[thingid]["类型"] == 3 and add > 0 then
						local v = add - shouldadd
						if v >= 0 and v < minvalue then
							minvalue = v
							selectid = thingid
						end
					end
				end
			end
		end
		--使用物品
		if UseThingEffect(selectid, pid) == 1 then
			instruct_32(selectid, -1)
		end
	--不在队
	else
		local extra = 0
		for i = 1, 4 do
			local thingid = JY.Person[pid]["携带物品" .. i]
			local tids = JY.Person[pid]["携带物品数量" .. i]
			if thingid >= 0 and tids > 0 then
				local add = Get_Add(thingid)
				if JY.Thing[thingid]["类型"] == 3 and add > 0 then
					local v = shouldadd - add
					if v < 0 then		--可以加满生命, 用其他方法找合适药品
						extra = 1
					elseif v < minvalue then
						minvalue = v
						selectid = thingid
					end
				end
			end
		end
		if extra == 1 then
			minvalue = math.huge
			for i = 1, 4 do
				local thingid = JY.Person[pid]["携带物品" .. i]
				local tids = JY.Person[pid]["携带物品数量" .. i]
				if thingid >= 0 and tids > 0 then
					local add = Get_Add(thingid)
					if JY.Thing[thingid]["类型"] == 3 and add > 0 then
						local v = add - shouldadd
						if v >= 0 and v < minvalue then
							minvalue = v
							selectid = thingid
						end
					end
				end
			end
		end
		--NPC使用物品
		if UseThingEffect(selectid, pid) == 1 then
			instruct_41(pid, selectid, -1)
		end
	end
	lib.Delay(500)
end

--自动逃跑
function War_AutoEscape()
  local pid = WAR.Person[WAR.CurID]["人物编号"]
  if JY.Person[pid]["体力"] <= 5 then
    return
  end
  local x, y = nil, nil
  War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)		 --计算移动步数
  WarDrawMap(1)
  ShowScreen()
  local array = {}
  local num = 0

  for i = 0, CC.WarWidth - 1 do
    for j = 0, CC.WarHeight - 1 do
      if GetWarMap(i, j, 3) < 128 then
        local minDest = math.huge
        for k = 0, WAR.PersonNum - 1 do
          if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[k]["我方"] and WAR.Person[k]["死亡"] == false then
            local dx = math.abs(i - WAR.Person[k]["坐标X"])
            local dy = math.abs(j - WAR.Person[k]["坐标Y"])
	          if dx + dy < minDest then		--计算当前距离敌人最近的位置
	            minDest = dx + dy
	          end
          end
        end
        num = num + 1
        array[num] = {}
        array[num].x = i
        array[num].y = j
        array[num].p = minDest
      end
    end
  end

  for i = 1, num - 1 do
    for j = i, num do
      if array[i].p < array[j].p then
        array[i], array[j] = array[j], array[i]
      end
    end
  end
  for i = 2, num do
    if array[i].p < array[1].p / 2 then
      num = i - 1
      break;
    end
  end
  for i = 1, num do
    array[i].p = array[i].p * 5 + GetMovePoint(array[i].x, array[i].y, 1)
  end
  for i = 1, num - 1 do
    for j = i, num do
      if array[i].p < array[j].p then
        array[i], array[j] = array[j], array[i]
      end
    end
  end
  x = array[1].x
  y = array[1].y

  War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
  War_MovePerson(x, y)	--移动到相应的位置
end

--自动战斗
function War_AutoMenu()
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	WAR.AutoFight = 1
	WAR.ShowHead = 0
	Cls()
	if JY.Person[pid]["禁用自动"] == 1 then
		return 0
	else
		War_Auto()
		return 1
	end
end

--计算可移动步数
--id 战斗人id，
--stepmax 最大步数，
--flag=0  移动，物品不能绕过，1 武功，用毒医疗等，不考虑挡路。
--flag=2  无视建筑
function War_CalMoveStep(id, stepmax, flag)
  CleanWarMap(3, 255)
  local x = WAR.Person[id]["坐标X"]
  local y = WAR.Person[id]["坐标Y"]
  local steparray = {}
  for i = 0, stepmax do
    steparray[i] = {}
    steparray[i].bushu = {}
    steparray[i].x = {}
    steparray[i].y = {}
  end
  SetWarMap(x, y, 3, 0)
  steparray[0].num = 1
  steparray[0].bushu[1] = stepmax
  steparray[0].x[1] = x
  steparray[0].y[1] = y
  War_FindNextStep(steparray, 0, flag, id)
  return steparray
end

--判断x,y是否为可移动位置
function War_CanMoveXY(x, y, flag)
	if flag == 2 then
		return true
	end
	if GetWarMap(x, y, 1) > 0 then
		return false
	end
	if flag == 0 then
		if CC.WarWater[GetWarMap(x, y, 0)] ~= nil then
			return false
		end
		if GetWarMap(x, y, 2) >= 0 then
			return false
		end
	end
	return true
end

--解毒菜单
function War_DecPoisonMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(2)
	WAR.ShowHead = 1
	Cls()
	return r
end

--是否背刺
function IsBackstab(warpid, wareid)
	return WAR.Person[warpid]["人方向"] == WAR.Person[wareid]["人方向"]
end

--判断攻击后面对的方向
function War_Direct(x1, y1, x2, y2)
	local x = x2 - x1
	local y = y2 - y1
	--lib.Debug("x "..x.."  y "..y)
	if x == 0 and y == 0 then
		return WAR.Person[WAR.CurID]["人方向"]
	end
	if math.abs(x) < math.abs(y) then
		if y > 0 then
			return 3
		else
			return 0
		end
	else
		if x > 0 then
			return 1
		else
			return 2
		end
	end
end

--医疗菜单
function War_DoctorMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(3)
	WAR.ShowHead = 1
	Cls()
	return r
end

---执行医疗，解毒用毒
---flag=1 用毒， 2 解毒，3 医疗 4 暗器
---thingid 暗器物品id
function War_ExecuteMenu(flag, thingid)
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local step = nil
	local sts =  nil
	if flag == 1 then
		step = math.modf(JY.Person[pid]["用毒能力"] / 40)
	elseif flag == 2 then
		step = math.modf(JY.Person[pid]["解毒能力"] / 40)
	elseif flag == 3 then
		step = math.modf(JY.Person[pid]["医疗能力"] / 40)
	elseif flag == 4 then
		step = math.modf(JY.Person[pid]["暗器技巧"] / 15) + 1
	end
	War_CalMoveStep(WAR.CurID, step, 1)
	--增加部分人物的7*7显示
	if pid == 0 and JY.Base["标准"] == 8 and flag == 3 then
		sts = 1
	elseif pid == 0 and JY.Base["标准"] == 9 and flag == 1 then
		sts = 1
	elseif match_ID(pid, 83) and flag == 4 then
		sts = 1
	end
	local x1, y1 = War_SelectMove(sts)
	if x1 == nil then
		lib.GetKey()
		Cls()
		return 0
	else
		return War_ExecuteMenu_Sub(x1, y1, flag, thingid)
	end
end

--选择武功的函数，手动和AI都经过这里
function War_FightSelectType(movefanwei, atkfanwei, x, y, wugong)
	local x0 = WAR.Person[WAR.CurID]["坐标X"]
	local y0 = WAR.Person[WAR.CurID]["坐标Y"]
	if x == nil and y == nil then
		x, y = War_KfMove(movefanwei, atkfanwei, wugong)
		if x == nil then
			lib.GetKey()
			Cls()
			return
		end
	--无酒不欢：AI也显示选择范围
	else
		WarDrawAtt(x, y, atkfanwei, 4)
		WarDrawMap(1, x, y)
		ShowScreen()
		
		CleanWarMap(7,0)
		lib.Delay(200)
	end
	if not War_Direct(x0, y0, x, y) then
		WAR.Person[WAR.CurID]["人方向"] = WAR.Person[WAR.CurID]["人方向"]
	else
		WAR.Person[WAR.CurID]["人方向"] = War_Direct(x0, y0, x, y)
	end
	SetWarMap(x, y, 4, 1)
	WAR.EffectXY = {}
	return x, y
end

--设置下一步可移动的坐标
function War_FindNextStep(steparray, step, flag, id)
	local num = 0
	local step1 = step + 1

	--ZOC判定
	local fujinnum = function(tx, ty)
		if flag ~= 0 or id == nil then
			return 0
		end
		local tnum = 0
		local wofang = WAR.Person[id]["我方"]
		local tv = nil
		tv = GetWarMap(tx + 1, ty, 2)
		if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
			tnum = 9999
		end
		tv = GetWarMap(tx - 1, ty, 2)
		if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
			tnum = 999
		end
		tv = GetWarMap(tx, ty + 1, 2)
		if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
			tnum = 999
		end
		tv = GetWarMap(tx, ty - 1, 2)
		if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
			tnum = 999
		end
		return tnum
	end

  for i = 1, steparray[step].num do
    if steparray[step].bushu[i] > 0 then
      steparray[step].bushu[i] = steparray[step].bushu[i] - 1
      local x = steparray[step].x[i]
      local y = steparray[step].y[i]
      if x + 1 < CC.WarWidth - 1 then
        local v = GetWarMap(x + 1, y, 3)
        if v == 255 and War_CanMoveXY(x + 1, y, flag) == true then
	        num = num + 1
	        steparray[step1].x[num] = x + 1
	        steparray[step1].y[num] = y
	        SetWarMap(x + 1, y, 3, step1)
	        steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x + 1, y)
      	end
      end

      if x - 1 > 0 then
        local v = GetWarMap(x - 1, y, 3)
        if v == 255 and War_CanMoveXY(x - 1, y, flag) == true then
	        num = num + 1
	        steparray[step1].x[num] = x - 1
	        steparray[step1].y[num] = y
	        SetWarMap(x - 1, y, 3, step1)
	        steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x - 1, y)
	      end
      end

      if y + 1 < CC.WarHeight - 1 then
        local v = GetWarMap(x, y + 1, 3)
        if v == 255 and War_CanMoveXY(x, y + 1, flag) == true then
	        num = num + 1
	        steparray[step1].x[num] = x
	        steparray[step1].y[num] = y + 1
	        SetWarMap(x, y + 1, 3, step1)
	        steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x, y + 1)
	      end
      end

      if y - 1 > 0 then
	      local v = GetWarMap(x, y - 1, 3)
	      if v == 255 and War_CanMoveXY(x, y - 1, flag) == true then
		      num = num + 1
		      steparray[step1].x[num] = x
		      steparray[step1].y[num] = y - 1
		      SetWarMap(x, y - 1, 3, step1)
		      steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x, y - 1)
	    	end
    	end
    end
  end
  if num == 0 then
    return
  end
  steparray[step1].num = num
  War_FindNextStep(steparray, step1, flag, id)
end

--判断是否能打到敌人
function War_GetCanFightEnemyXY()
	local num, x, y = nil, nil, nil
	num, x, y = War_realjl(WAR.CurID)
	if num == -1 then
		return
	end
	return x, y
end

--移动
function War_MoveMenu()
  if WAR.Person[WAR.CurID]["人物编号"] ~= -1 then
    WAR.ShowHead = 0
    if WAR.Person[WAR.CurID]["移动步数"] <= 0 then
      return 0
    end
    War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
    local r = nil
    local x, y = War_SelectMove()
    if x ~= nil then
      War_MovePerson(x, y, 1)
      r = 1
    else
      r = 0
      WAR.ShowHead = 1
      Cls()
    end
    lib.GetKey()
    return r
  else
    local ydd = {}
    local n = 1
    for i = 0, WAR.PersonNum - 1 do
      if WAR.Person[i]["我方"] ~= WAR.Person[WAR.CurID]["我方"] and WAR.Person[i]["死亡"] == false then
        ydd[n] = i
        n = n + 1
      end
    end
    local dx = ydd[math.random(n - 1)]
    local DX = WAR.Person[dx]["坐标X"]
    local DY = WAR.Person[dx]["坐标Y"]
    local YDX = {DX + 1, DX - 1, DX}
    local YDY = {DY + 1, DY - 1, DY}
    local ZX = YDX[math.random(3)]
    local ZY = YDY[math.random(3)]
    if not SceneCanPass(ZX, ZY) or GetWarMap(ZX, ZY, 2) < 0 then
      SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
      SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
      WAR.Person[WAR.CurID]["坐标X"] = ZX
      WAR.Person[WAR.CurID]["坐标Y"] = ZY
      SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
      SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
    end
  end
  return 1
end

--人物移动
function War_MovePerson(x, y, flag)
  local x1 = x
  local y1 = y
  if not flag then
    flag = 0
  end
  local movenum = GetWarMap(x, y, 3)
  local movetable = {}
  for i = movenum, 1, -1 do
    movetable[i] = {}
    movetable[i].x = x
    movetable[i].y = y
    if GetWarMap(x - 1, y, 3) == i - 1 then
      x = x - 1
      movetable[i].direct = 1
    elseif GetWarMap(x + 1, y, 3) == i - 1 then
      x = x + 1
      movetable[i].direct = 2
    elseif GetWarMap(x, y - 1, 3) == i - 1 then
      y = y - 1
      movetable[i].direct = 3
    elseif GetWarMap(x, y + 1, 3) == i - 1 then
      y = y + 1
      movetable[i].direct = 0
    end
  end
	--减少移动步数
	movetable.num = movenum
	movetable.now = 0
	WAR.Person[WAR.CurID].Move = movetable
	if WAR.Person[WAR.CurID]["移动步数"] < movenum then
		movenum = WAR.Person[WAR.CurID]["移动步数"]
		WAR.Person[WAR.CurID]["移动步数"] = 0
	else
		WAR.Person[WAR.CurID]["移动步数"] = WAR.Person[WAR.CurID]["移动步数"] - movenum
	end
	--移动人物
	--标主的特殊显示
	--七夕龙女的论剑奖励代表是否学有迷踪步
	if WAR.Person[WAR.CurID]["人物编号"] == 0 and JY.Base["标准"] > 0 and JY.Person[615]["论剑奖励"] == 1 and movenum > 2 then
		local a = 0
		local gender = 0
		if JY.Person[0]["性别"] > 0 then
			gender = 1
		end
		for i = 1, movenum do
			local t1 = lib.GetTime()
			if a == 6 then
				a = 0
			end
			if i == 1 then
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
				SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
			end
			if i > 3 then
				SetWarMap(movetable[i-3].x, movetable[i-3].y, 2, -1)
				SetWarMap(movetable[i-3].x, movetable[i-3].y, 5, -1)
			end
			if i == movenum then
				SetWarMap(movetable[i-2].x, movetable[i-2].y, 2, -1)
				SetWarMap(movetable[i-2].x, movetable[i-2].y, 5, -1)
				SetWarMap(movetable[i-1].x, movetable[i-1].y, 2, -1)
				SetWarMap(movetable[i-1].x, movetable[i-1].y, 5, -1)
			end
			WAR.Person[WAR.CurID]["坐标X"] = movetable[i].x
			WAR.Person[WAR.CurID]["坐标Y"] = movetable[i].y
			WAR.Person[WAR.CurID]["人方向"] = movetable[i].direct
			if i < movenum then
				WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic2(WAR.CurID, gender) + (a)*2
			else
				WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)
			end
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
			WarDrawMap(0)
			ShowScreen()
			a = a + 1
			local t2 = lib.GetTime()
			if i < movenum and t2 - t1 < CC.BattleDelay then
			  lib.Delay(CC.BattleDelay - (t2 - t1))
			end
		end
	else
		for i = 1, movenum do
			local t1 = lib.GetTime()
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
			WAR.Person[WAR.CurID]["坐标X"] = movetable[i].x
			WAR.Person[WAR.CurID]["坐标Y"] = movetable[i].y
			WAR.Person[WAR.CurID]["人方向"] = movetable[i].direct
			WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
			WarDrawMap(0)
			ShowScreen()
			local t2 = lib.GetTime()
			if i < movenum and t2 - t1 < 2 * CC.BattleDelay then
			  lib.Delay(2 * CC.BattleDelay - (t2 - t1))
			end
		end
	end
	--主运轻功的话遇到ZOC移动不清0，反之清0
	if JY.Person[WAR.Person[WAR.CurID]["人物编号"]]["主运轻功"] == 0 then
		local fujinnum = function(tx, ty)
			local tnum = 0
			local wofang = WAR.Person[WAR.CurID]["我方"]
			local tv = nil
			tv = GetWarMap(tx + 1, ty, 2)
			if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx - 1, ty, 2)
			if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx, ty + 1, 2)
			if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx, ty - 1, 2)
			if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
				tnum = 999
			end
			return tnum
		end
		if fujinnum(WAR.Person[WAR.CurID]["坐标X"],WAR.Person[WAR.CurID]["坐标Y"]) ~= 0 then
			WAR.Person[WAR.CurID]["移动步数"] = 0
		end
	end
end

---用毒菜单
function War_PoisonMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(1)
	WAR.ShowHead = 1
	Cls()
	return r
end

--战斗休息
function War_RestMenu()
	if WAR.CurID and WAR.CurID >= 0  then
		local pid = WAR.Person[WAR.CurID]["人物编号"]
		--[[走火不能休息
		if WAR.tmp[1000 + pid] == 1 then
			return 1
		end
		local vv = math.modf(JY.Person[pid]["体力"] / 100 - JY.Person[pid]["受伤程度"] / 50 - JY.Person[pid]["中毒程度"] / 50) + 2
		if WAR.Person[WAR.CurID]["移动步数"] > 0 then
			vv = vv + 2
		end
		if inteam(pid) then
			vv = vv + math.random(3)
		else
			vv = vv + 6
		end
		vv = (vv) / 120
		local v = 3 + Rnd(3)
		WAR.Person[WAR.CurID]["体力点数"] = AddPersonAttrib(pid, "体力", v)
		if JY.Person[pid]["体力"] > 0 then
			v = 3 + math.modf(JY.Person[pid]["生命最大值"] / JY.Person[pid]["血量翻倍"] * (vv))
			WAR.Person[WAR.CurID]["生命点数"] = AddPersonAttrib(pid, "生命", v)
			v = 3 + math.modf(JY.Person[pid]["内力最大值"] * (vv))
			WAR.Person[WAR.CurID]["内力点数"] = AddPersonAttrib(pid, "内力", v)
		end

		War_Show_Count(WAR.CurID);		--显示当前控制人的点数]]

		--阿凡提休息带蓄力+防御
		if match_ID(pid, 606) then
			Cls()
			WAR.Actup[pid] = 2;
			WAR.Defup[pid] = 1
			CurIDTXDH(WAR.CurID, 85,1);
			DrawStrBox(-1, -1, "运筹帷幄·决胜千里", LimeGreen, CC.DefaultFont,C_GOLD)
			ShowScreen()
			lib.Delay(400)
			return 1;
		else
			return 1
		end
	end
end

--战斗查看状态
function War_StatusMenu()
	local x = WAR.Person[WAR.CurID]["坐标X"];
    local y = WAR.Person[WAR.CurID]["坐标Y"];
    WAR.ShowHead = 0
    War_CalMoveStep(WAR.CurID, 128, 1);
    WarDrawMap(1, x, y);
    ShowScreen();
    x, y = War_SelectMove()
	if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
		local tdID = lib.GetWarMap(x, y, 2)
		local eid = WAR.Person[tdID]["人物编号"]
		ShowPersonStatus(1, eid)
	end
    --if x == nil then return end
    WAR.ShowHead = 1
end

--战斗物品菜单
function War_ThingMenu()
	WAR.ShowHead = 0
	local thing = {}
	local thingnum = {}
	for i = 0, CC.MyThingNum - 1 do
		thing[i] = -1
		thingnum[i] = 0
	end
	local num = 0
	for i = 0, CC.MyThingNum - 1 do
		local id = JY.Base["物品" .. i + 1]
		if id >= 0 and (JY.Thing[id]["类型"] == 1 or JY.Thing[id]["类型"] == 3 or JY.Thing[id]["类型"] == 4) then
			thing[num] = id
			thingnum[num] = JY.Base["物品数量" .. i + 1]
			num = num + 1
		end
	end
	local r = SelectThing(thing, thingnum)
	Cls()
	local rr = 0
	if r >= 0 and UseThing(r) == 1 then
		rr = 1
	end
	WAR.ShowHead = 1
	Cls()
	return rr
end


--自动战斗判断是否能医疗
function War_ThinkDoctor()
  local pid = WAR.Person[WAR.CurID]["人物编号"]
  if JY.Person[pid]["体力"] < 50 or JY.Person[pid]["医疗能力"] < 20 then
    return -1
  end
  local rate = -1
  local v = JY.Person[pid]["生命最大值"] - JY.Person[pid]["生命"]
  if JY.Person[pid]["医疗能力"] < v / 4 then
    rate = 30
  elseif JY.Person[pid]["医疗能力"] < v / 3 then
      rate = 50
  elseif JY.Person[pid]["医疗能力"] < v / 2 then
      rate = 70
  else
    rate = 90
  end
  if Rnd(100) < rate then
    return 5
  end
  return -1
end

--能否吃药增加参数
--flag=2 生命，3内力；4体力  6 解毒
function War_ThinkDrug(flag)
  local pid = WAR.Person[WAR.CurID]["人物编号"]
  local str = nil
  local r = -1
  if flag == 2 then
    str = "加生命"
  elseif flag == 3 then
    str = "加内力"
  elseif flag == 4 then
    str = "加体力"
  elseif flag == 6 then
    str = "加中毒解毒"
  else
    return r
  end
  local function Get_Add(thingid)
    if flag == 6 then
      return -JY.Thing[thingid][str]
    else
      return JY.Thing[thingid][str]
    end
  end

  --身上是否有药品
  if inteam(pid) and WAR.Person[WAR.CurID]["我方"] == true then
    for i = 1, CC.MyThingNum do
      local thingid = JY.Base["物品" .. i]
      if thingid >= 0 and JY.Thing[thingid]["类型"] == 3 and Get_Add(thingid) > 0 then
        r = flag
        break;
      end
    end
  else
    for i = 1, 4 do
      local thingid = JY.Person[pid]["携带物品" .. i]
      if thingid >= 0 and JY.Thing[thingid]["类型"] == 3 and Get_Add(thingid) > 0 then
        r = flag
        break;
      end
    end
  end
  return r
end

--使用暗器
function War_UseAnqi(id)
	return War_ExecuteMenu(4, id)
end

--初始化战斗数据
function WarLoad(warid)
	WarSetGlobal()
	local data = Byte.create(CC.WarDataSize)
	Byte.loadfile(data, CC.WarFile, warid * CC.WarDataSize, CC.WarDataSize)
	LoadData(WAR.Data, CC.WarData_S, data)
	WAR.ZDDH = warid
end

--加载战斗地图
function WarLoadMap(mapid)
	lib.Debug(string.format("load war map %d", mapid))
	lib.LoadWarMap(CC.WarMapFile[1], CC.WarMapFile[2], mapid, 8, CC.WarWidth, CC.WarHeight)
end


function GetWarMap(x, y, level)
	if x > 63 or x < 0 or y > 63 or y < 0 then
		return
	end
	return lib.GetWarMap(x, y, level)
end

function SetWarMap(x, y, level, v)
	if x > 63 or x < 0 or y > 63 or y < 0 then
		return
	end
	lib.SetWarMap(x, y, level, v)
end

function CleanWarMap(level, v)
	lib.CleanWarMap(level, v)
end

--设置人物贴图
function WarSetPerson()
	CleanWarMap(2, -1)
	CleanWarMap(5, -1)
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 2, i)
			SetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 5, WAR.Person[i]["贴图"])
		end
	end
end

--显示武功动画，人物受伤动画，音效等
function War_ShowFight(pid, wugong, wugongtype, level, x, y, eft, ZHEN_ID)
	--攻击时不显示血条
	WAR.ShowHP = 0

	--没有合击
	if not ZHEN_ID then
		ZHEN_ID = -1
	end

	--内功
	if wugongtype == 6 then
		wugongtype = WAR.NGXS
	end

	--无酒不欢：设置一下新的动画顺序
	if wugongtype == 2 then
		wugongtype = 1
	elseif wugongtype > 2 and wugongtype < 6 then
		wugongtype = wugongtype - 1
	end

	local x0 = WAR.Person[WAR.CurID]["坐标X"]
	local y0 = WAR.Person[WAR.CurID]["坐标Y"]

	local using_anqi = 0
	local anqi_name;
	--暗器动画
	if wugongtype == -1 then
		using_anqi = 1
		anqi_name = JY.Thing[eft]["名称"]
		--何铁手含沙射影
		if match_ID(pid, 83) then
			anqi_name = "含沙射影·"..anqi_name
		end
		eft = JY.Thing[eft]["暗器动画编号"]
	end

	--扫地老僧  随机动画
	if match_ID(pid, 114) then
		eft = math.random(100)
	end

	--黯然极意动画
	if wugong == 25 and WAR.ARJY == 1 then
		eft = 7
	end

	--金蛇奥义动画
	if wugong == 40 and WAR.JSAY == 1 then
		eft = 44
	end

	--进阶万花
	if wugong == 30 and PersonKF(pid,175) then
		eft = 139
	end
	--进阶泰山
	if wugong == 31 and PersonKF(pid,175) then
		eft = 138
	end
	--进阶云雾
	if wugong == 32 and PersonKF(pid,175) then
		eft = 142
	end
	--进阶万岳
	if wugong == 33 and PersonKF(pid,175) then
		eft = 140
	end
	--进阶太岳
	if wugong == 34 and PersonKF(pid,175) then
		eft = 141
	end

	--无酒不欢的特效动画
	if pid == 0 and JY.Base["特殊"] == 1 then
		if JY.Person[0]["性别"] == 0 then
			eft = 65
		else
			eft = 8
		end
	end

	--杨康的杨家枪法
	if match_ID(pid,650) and wugong == 68 then
		eft = 150
	end

	--无招胜有招动画
	if wugong == 47 and WAR.FQY == 1 then
		eft = 84
	end

	local ex, ey = -1, -1;

	--测试动画
	--eft = 110;

	--主角有几率出随机动画
	if pid == 0 and GetS(53, 0, 4, 5) == 1 and JLSD(0,30,pid)  then
		eft = 110;
	end

	--指定XY，那么只显示在一个点显示动画
	if eft == 110 then
		ex, ey = x, y;
	end

	--六脉神剑的类型设置为拳法
	if wugong == 49 then
		wugongtype = 1
	end

	--合击动画
	local ZHEN_pid, ZHEN_type, ZHEN_startframe, ZHEN_fightframe = nil, nil, nil, nil
	if ZHEN_ID >= 0 then
		ZHEN_pid = WAR.Person[ZHEN_ID]["人物编号"]
		ZHEN_type = wugongtype
		ZHEN_startframe = 0
		ZHEN_fightframe = 0
	end

	local fightdelay, fightframe, sounddelay = nil, nil, nil
	if wugongtype >= 0 then
		fightdelay = JY.Person[pid]["出招动画延迟" .. wugongtype + 1]
		fightframe = JY.Person[pid]["出招动画帧数" .. wugongtype + 1]
		sounddelay = JY.Person[pid]["武功音效延迟" .. wugongtype + 1]
	else
		fightdelay = 0
		fightframe = -1
		sounddelay = -1
	end

	if fightdelay == 0 or fightframe == 0 then
		for i = 1, 5 do
			if JY.Person[pid]["出招动画帧数" .. i] ~= 0 then
				fightdelay = JY.Person[pid]["出招动画延迟" .. i]
				fightframe = JY.Person[pid]["出招动画帧数" .. i]
				sounddelay = JY.Person[pid]["武功音效延迟" .. i]
				wugongtype = i - 1
			end
		end
	end

	if ZHEN_ID >= 0 then
		if JY.Person[ZHEN_pid]["出招动画帧数" .. ZHEN_type + 1] == 0 then
			for i = 1, 5 do
				if JY.Person[ZHEN_pid]["出招动画帧数" .. i] ~= 0 then
					ZHEN_type = i - 1
					ZHEN_fightframe = JY.Person[ZHEN_pid]["出招动画帧数" .. i]
				end
			end
		else
			ZHEN_fightframe = JY.Person[ZHEN_pid]["出招动画帧数" .. ZHEN_type + 1]
		end
	end

	local framenum = fightdelay + CC.Effect[eft]
	local startframe = 0
	if wugongtype >= 0 then
		for i = 0, wugongtype - 1 do
			startframe = startframe + 4 * JY.Person[pid]["出招动画帧数" .. i + 1]
		end
	end
	if ZHEN_ID >= 0 and ZHEN_type >= 0 then
		for i = 0, ZHEN_type - 1 do
			ZHEN_startframe = ZHEN_startframe + 4 * JY.Person[ZHEN_pid]["出招动画帧数" .. i + 1]
		end
	end

	local starteft = 0
	for i = 0, eft - 1 do
		starteft = starteft + CC.Effect[i]
	end

	WAR.Person[WAR.CurID]["贴图类型"] = 0
	WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)
	if ZHEN_ID >= 0 then
		WAR.Person[ZHEN_ID]["贴图类型"] = 0
		WAR.Person[ZHEN_ID]["贴图"] = WarCalPersonPic(ZHEN_ID)
	end

	local oldpic = WAR.Person[WAR.CurID]["贴图"] / 2		--当前贴图的位置
	local oldpic_type = 0
	local oldeft = -1
	local kfname = JY.Wugong[wugong]["名称"]
	local showsize = CC.FontBig
	local showx = CC.ScreenW / 2 - showsize * string.len(kfname) / 4
	local hb = GetS(JY.SubScene, x0, y0, 4)

	--显示武功，放到特效文字4
	if wugong ~= 0 then
		if WAR.LHQ_BNZ == 1 then
			kfname = "般若掌"
		end
		if WAR.JGZ_DMZ == 1 then
			kfname = "达摩掌"
		end
		if WAR.WD_CLSZ == 1 then
			kfname = "赤练神掌"
		end
	end

	--独孤求败的反击文字
	if WAR.hit_DGQB == 1 then
		kfname = "无我无剑"
	end

	--金蛇奥义
	if WAR.JSAY == 1 then
		kfname = "奥义·金蛇狂舞"
	end

	--何铁手五毒显示倍数
	if wugong == 3 and match_ID(pid, 83) and WAR.HTS > 0 then
		kfname = kfname.." X "..WAR.HTS
	end

	--内功显示随机到的系
	if WAR.NGXS > 0 then
		local display = {"土拳","火指","木剑","金刀","水奇"}
		kfname = kfname.."·"..display[WAR.NGXS]
	end

	if ZHEN_ID >= 0 then
		kfname = "双人合击·"..kfname
	end

	--特效文字4和武功名称显示
	if wugong > 0 or WAR.hit_DGQB == 1 then				--使用武功时才显示，独孤求败反击也显示
		if WAR.Person[WAR.CurID]["特效文字4"] ~= nil then
			for i=1, 20 do
				local n, strs = Split(WAR.Person[WAR.CurID]["特效文字4"], "·");
				local len = string.len(WAR.Person[WAR.CurID]["特效文字4"]);
				local color = RGB(255,40,10);
				local off = 0;
				for j=1, n do
					if strs[j] == "连击" or strs[j] == "天赋外功.炉火纯青"
					or strs[j] == "碧箫声里双鸣凤" or strs[j] == "英雄无双风流婿" or strs[j] == "刀光掩映孔雀屏"
					or strs[j] == "太极之形.圆转不断" then
						color = M_LightBlue;
					elseif strs[j] == "左右互搏" then
						color = M_DarkOrange
					else
						color = RGB(255,40,10);
					end
					if j > 1 then
						strs[j] = strs[j];
						off = off + 42
					end
					DrawStrBox(-1, 10 + off, strs[j], color, 10+i)
					--off = off + string.len(strs[j])*(CC.DefaultFont+i/2)/4 + (CC.DefaultFont+i/2)*3/2;
				end
				ShowScreen()
				lib.Delay(10)
				if i == 20 then
					lib.Delay(30)
				end
				Cls()
			end
		end
		--武功显示
		for i = 5, 10 do
			KungfuString(kfname, CC.ScreenW / 2 -#kfname/2, CC.ScreenH / 3 - 20 - hb  , C_GOLD, CC.FontBig+i, CC.FontName, 0)
			ShowScreen()

			lib.Delay(2)
			if i == 10 then
				lib.Delay(300)
			end
			Cls()
		end
	end

	--暗器显示
	if using_anqi == 1 then
		for i = 5, 10 do
			if WAR.KHSZ == 1 then
				KungfuString("葵花神针", CC.ScreenW / 2 -#anqi_name/2, CC.ScreenH / 3 - 20 - hb  , C_RED, CC.FontBig+i, CC.FontName, 0)
			else
				KungfuString(anqi_name.."×"..WAR.AQBS, CC.ScreenW / 2 -#anqi_name/2, CC.ScreenH / 3 - 20 - hb  , C_GOLD, CC.FontBig+i, CC.FontName, 0)
			end
			ShowScreen()

			lib.Delay(2)
			if i == 10 then
				lib.Delay(300)
			end
			Cls()
		end
	end

  --显示攻击动画
  for i = 0, framenum - 1 do
	if JY.Restart == 1 then
		break
	end
    local tstart = lib.GetTime()
    local mytype = nil
    if fightframe > 0 then
      WAR.Person[WAR.CurID]["贴图类型"] = 1
      mytype = 4 + WAR.CurID
      if i < fightframe then
        WAR.Person[WAR.CurID]["贴图"] = (startframe + WAR.Person[WAR.CurID]["人方向"] * fightframe + i) * 2
      end
    else
      WAR.Person[WAR.CurID]["贴图类型"] = 0
      WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)
      mytype = 0
    end

    if ZHEN_ID >= 0 then
      if ZHEN_fightframe > 0 then
        WAR.Person[ZHEN_ID]["贴图类型"] = 1
        if i < ZHEN_fightframe and i < framenum - 1 then
          WAR.Person[ZHEN_ID]["贴图"] = (ZHEN_startframe + WAR.Person[ZHEN_ID]["人方向"] * ZHEN_fightframe + i) * 2
        else
          WAR.Person[ZHEN_ID]["贴图"] = WarCalPersonPic(ZHEN_ID)
        end
      else
        WAR.Person[ZHEN_ID]["贴图类型"] = 0
        WAR.Person[ZHEN_ID]["贴图"] = WarCalPersonPic(ZHEN_ID)
      end
      SetWarMap(WAR.Person[ZHEN_ID]["坐标X"], WAR.Person[ZHEN_ID]["坐标Y"], 5, WAR.Person[ZHEN_ID]["贴图"])
    end

    if i == sounddelay then
      PlayWavAtk(JY.Wugong[wugong]["出招音效"])		--
    end

    if i == fightdelay then
      PlayWavE(eft)
    end

	--六脉神剑的音效
    if i == 1 and WAR.LMSJwav == 1 then
		PlayWavAtk(31)
		WAR.LMSJwav = 0
    end

    local pic = WAR.Person[WAR.CurID]["贴图"] / 2

    lib.SetClip(0, 0, 0, 0)

    oldpic = pic
    oldpic_type = mytype

    --无酒不欢：攻击特效文字显示 8-3
    if i < fightdelay then
		WarDrawMap(4, pic * 2, mytype, -1)

		--袁承志暴击倍数显示
		--仅限我方
		if match_ID(pid, 54) and inteam(pid) and using_anqi == 0 and WAR.BJ == 1 then
			local cri_factor = 1.5 + 0.1 * JY.Base["天书数量"]
			KungfuString("暴击×"..cri_factor, CC.ScreenW -230 +i*2, CC.ScreenH / 3 - 50 - hb -i*2, C_RED, CC.FontBig+i*2, CC.FontName, 0)
  		end

		if i == 1 and WAR.Person[WAR.CurID]["特效动画"] ~= -1 then
			local theeft = WAR.Person[WAR.CurID]["特效动画"]
			local sf = 0
			for ii = 0, theeft - 1 do
				sf = sf + CC.Effect[ii]
			end
			local ssid = lib.SaveSur(CC.ScreenW/2 - 11 * CC.XScale, CC.ScreenH/2 - hb - 18 * CC.YScale, CC.ScreenW/2 + 11 * CC.XScale, CC.ScreenH/2 - hb + 5 * CC.YScale)

			for ii = 1, CC.Effect[theeft] do
				lib.GetKey()
				lib.PicLoadCache(3, (sf+ii) * 2, CC.ScreenW/2 , CC.ScreenH/2  - hb, 2, 192, nil, 0, 0)
				if WAR.Person[WAR.CurID]["特效文字0"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["特效文字0"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
				end
				if WAR.Person[WAR.CurID]["特效文字1"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["特效文字1"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_RED, CC.FontSmall5, CC.FontName, 3)
				end
				if WAR.Person[WAR.CurID]["特效文字2"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["特效文字2"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_GOLD, CC.FontSmall5, CC.FontName, 2)
				end
				if WAR.Person[WAR.CurID]["特效文字3"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["特效文字3"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_WHITE, CC.FontSmall5, CC.FontName, 1)
				end
				ShowScreen()
				lib.Delay(30)
				lib.LoadSur(ssid, CC.ScreenW/2 - 11 * CC.XScale, CC.ScreenH/2 - hb - 18 * CC.YScale)

			end
			lib.FreeSur(ssid)
			WAR.Person[WAR.CurID]["特效动画"] = -1
		else
			if WAR.Person[WAR.CurID]["特效文字0"] ~= nil or WAR.Person[WAR.CurID]["特效文字1"] ~= nil or WAR.Person[WAR.CurID]["特效文字2"] ~= nil or WAR.Person[WAR.CurID]["特效文字3"] ~= nil then
				KungfuString(WAR.Person[WAR.CurID]["特效文字0"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
				KungfuString(WAR.Person[WAR.CurID]["特效文字1"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_RED, CC.FontSmall5, CC.FontName, 3)
				KungfuString(WAR.Person[WAR.CurID]["特效文字2"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_GOLD, CC.FontSmall5, CC.FontName, 2)
				KungfuString(WAR.Person[WAR.CurID]["特效文字3"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_WHITE, CC.FontSmall5, CC.FontName, 1)
				lib.Delay(30)
			end
		end
    else
		starteft = starteft + 1

        lib.SetClip(0, 0, 0, 0)

        WarDrawMap(4, pic * 2, mytype, (starteft) * 2, nil, 3, ex, ey)

		--DrawString(200,200,starteft,C_WHITE,CC.DefaultFont);

		oldeft = starteft

		local estart = lib.GetTime()
		if CC.BattleDelay - (estart - tstart) > 0 then
			lib.Delay(CC.BattleDelay - (estart - tstart));
		end
    end

	ShowScreen()
    lib.SetClip(0, 0, 0, 0)
    local tend = lib.GetTime()
    if CC.BattleDelay - (tend - tstart) > 0 then
    	lib.Delay(CC.BattleDelay - (tend - tstart));
    end
	lib.GetKey();
  end

  lib.SetClip(0, 0, 0, 0)
  WAR.Person[WAR.CurID]["贴图类型"] = 0
  WAR.Person[WAR.CurID]["贴图"] = WarCalPersonPic(WAR.CurID)

  --无酒不欢：命中的人物用白色表示
  WarSetPerson()
  WarDrawMap(0)
  ShowScreen()
  lib.Delay(200)
  WarDrawMap(2)
  ShowScreen()
  lib.Delay(200)
  WarDrawMap(0)
  ShowScreen()

  --计算攻击到的人
  local HitXY = {}
  local HitXYNum = 0
  local hnum = 13;		--HitXY的长度个数
  for i = 0, WAR.PersonNum - 1 do
    local x1 = WAR.Person[i]["坐标X"]
    local y1 = WAR.Person[i]["坐标Y"]
	--被特效击中的也显示
    if WAR.Person[i]["死亡"] == false and (GetWarMap(x1, y1, 4) > 1 or WAR.TXXS[WAR.Person[i]["人物编号"]] == 1) then
      SetWarMap(x1, y1, 4, 1)
      --local n = WAR.Person[i]["点数"]
      local hp = WAR.Person[i]["生命点数"];
      local mp = WAR.Person[i]["内力点数"];
      local tl = WAR.Person[i]["体力点数"];
      local ed = WAR.Person[i]["中毒点数"];
      local dd = WAR.Person[i]["解毒点数"];
      local ns = WAR.Person[i]["内伤点数"];

      HitXY[HitXYNum] = {x1, y1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};		--x, y, 生命, 内力, 体力, 封穴, 流血, 中毒, 解毒, 内伤，冰封，灼烧

		if hp ~= nil then
	      if hp == 0 then			--显示受到的生命
	      	HitXY[HitXYNum][3] = "miss";
	      elseif hp > 0 then
	      	HitXY[HitXYNum][3] = "+"..hp;
	      else
	      	HitXY[HitXYNum][3] = hp;
	      end
	    end


      if mp ~= nil then			--显示内力变化
      	if mp > 0 then
      		HitXY[HitXYNum][5] = "内力+"..mp;
      	elseif mp ==  0 then
      		HitXY[HitXYNum][5] = nil;			--变化为0时不显示
      	else
      		HitXY[HitXYNum][5] = "内力"..mp;
      	end
      end

      if tl ~= nil then			--显示体力变化
      	if tl > 0 then
      		HitXY[HitXYNum][6] = "体力+"..tl;
      	elseif tl == 0 then
      		HitXY[HitXYNum][6] = nil;
      	else
      		HitXY[HitXYNum][6] = "体力"..tl;
      	end
      end

      if WAR.FXXS[WAR.Person[i]["人物编号"]] ~= nil and WAR.FXXS[WAR.Person[i]["人物编号"]] == 1 then			--显示是否封穴
       	HitXY[HitXYNum][7] = "封穴 "..WAR.FXDS[WAR.Person[i]["人物编号"]];
       	WAR.FXXS[WAR.Person[i]["人物编号"]] = 0
      end

      if WAR.LXXS[WAR.Person[i]["人物编号"]] ~=nil and WAR.LXXS[WAR.Person[i]["人物编号"]] == 1 then		--显示是否被流血
      	HitXY[HitXYNum][8] = "流血 "..WAR.LXZT[WAR.Person[i]["人物编号"]];
        WAR.LXXS[WAR.Person[i]["人物编号"]] = 0
      end

      if ed ~= nil then				--显示中毒
      	if ed == 0 then
      		HitXY[HitXYNum][9] = nil;
      	else
      		HitXY[HitXYNum][9] = "中毒↑"..ed;
      	end
      end

      if dd ~= nil then			--显示解毒
      	if dd  == 0 then
      		HitXY[HitXYNum][4] = nil;
      	else
      		HitXY[HitXYNum][4] = "中毒↓"..dd;
      	end
      end

      if ns ~= nil then		--显示内伤
      	if ns == 0 then
      		HitXY[HitXYNum][10] = nil;
      	elseif ns > 0 then
      		HitXY[HitXYNum][10] = "内伤↑"..ns;
      	else
      		HitXY[HitXYNum][10] = "内伤↓"..ns;
      	end
      end

		if WAR.BFXS[WAR.Person[i]["人物编号"]] == 1 then		--显示是否被冰封
			HitXY[HitXYNum][11] = "冰封 "..JY.Person[WAR.Person[i]["人物编号"]]["冰封程度"];
			WAR.BFXS[WAR.Person[i]["人物编号"]] = 0
		end

		if WAR.ZSXS[WAR.Person[i]["人物编号"]] == 1 then		--显示是否被灼烧
			HitXY[HitXYNum][12] = "灼烧 "..JY.Person[WAR.Person[i]["人物编号"]]["灼烧程度"];
			WAR.ZSXS[WAR.Person[i]["人物编号"]] = 0
		end

		HitXYNum = HitXYNum + 1
    end

		--偷东西，斗转不可偷
		if WAR.TD > -1 then
			if WAR.TD == 118 then
				say("１想要从我慕容复手中偷东西？哼哼，下辈子吧！", 51,0)
			else
				instruct_2(WAR.TD, WAR.TDnum)
				Cls()
			end
			WAR.TD = -1
		end
	end

	local minx = 0;
	local maxx = CC.ScreenW;
	local miny = 0;
	local maxy = CC.ScreenH;

	local sssid = lib.SaveSur(minx, miny, maxx, maxy)
	--挨打特效文字显示
	for ii = 1, 20 do
		if JY.Restart == 1 then
			break
		end
		local yanshi = false
		local yanshi2 = false		--无动画时的延迟
		for i = 0, WAR.PersonNum - 1 do
			lib.GetKey()
			if WAR.Person[i]["死亡"] == false then
				local theeft = WAR.Person[i]["特效动画"]
				if theeft ~= -1 and ii < CC.Effect[theeft] then
					local dx = WAR.Person[i]["坐标X"] - x0
					local dy = WAR.Person[i]["坐标Y"] - y0
					local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
					local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
					local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

					local py = 0

					ry = ry - hb
					starteft = ii
					for i = 0, WAR.Person[i]["特效动画"] - 1 do
						starteft = starteft + CC.Effect[i]
					end

					--剑胆琴心动画位置
					if theeft == 125 then
						py = CC.YScale * 5
					end

					--喵姐的免疫攻击动画位置
					if theeft == 135 then
						py = CC.YScale * 2
					end

					--五岳剑诀，以剑御气动画位置
					if theeft == 137 then
						py = CC.YScale * 18
						starteft = starteft + 12
					end

					--倾国动画位置
					if theeft == 149 then
						py = CC.YScale * 11
					end

					lib.PicLoadCache(3, (starteft) * 2, rx, ry + py, 2, 192, nil, 0, 0)

					--无酒不欢：特效文字一起出，不再用依次显示的方式
					--if ii < TPXS[i] * TP and (TPXS[i] - 1) * TP < ii then	
						KungfuString(WAR.Person[i]["特效文字3"], rx, ry, C_WHITE, CC.FontSmall5, CC.FontName, 1)
						KungfuString(WAR.Person[i]["特效文字2"], rx, ry, C_GOLD, CC.FontSmall5, CC.FontName, 2)
						KungfuString(WAR.Person[i]["特效文字1"], rx, ry, C_RED, CC.FontSmall5, CC.FontName, 3)
						KungfuString(WAR.Person[i]["特效文字0"], rx, ry, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
						yanshi = true
					--end
				else
					--蓝烟清： 修正无动画时不显示文字的BUG
					if i~= WAR.CurID and theeft == -1 and ((WAR.Person[i]["特效文字1"] ~= nil and WAR.Person[i]["特效文字1"] ~= "  ") or (WAR.Person[i]["特效文字2"] ~= nil and WAR.Person[i]["特效文字2"] ~= "  ")  or (WAR.Person[i]["特效文字3"] ~= nil and WAR.Person[i]["特效文字3"] ~= "  ") ) then
						local dx = WAR.Person[i]["坐标X"] - x0
						local dy = WAR.Person[i]["坐标Y"] - y0
						local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
						local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
						local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

						ry = ry - hb

						KungfuString(WAR.Person[i]["特效文字3"], rx, ry, C_WHITE, CC.FontSmall5, CC.FontName, 1)
						KungfuString(WAR.Person[i]["特效文字2"], rx, ry, C_GOLD, CC.FontSmall5, CC.FontName, 2)
						KungfuString(WAR.Person[i]["特效文字1"], rx, ry, C_RED, CC.FontSmall5, CC.FontName, 3)
						KungfuString(WAR.Person[i]["特效文字0"], rx, ry, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
						yanshi2 = true
					end
				end
			end
		end
		if yanshi then
		  lib.ShowSurface(0)
		  lib.LoadSur(sssid, minx, miny)
		  lib.Delay(30)
		elseif yanshi2 then
		  lib.ShowSurface(0)
		  lib.LoadSur(sssid, minx, miny)
		  lib.Delay(10)
		end
	end
	lib.FreeSur(sssid)
	Cls()	--显示点数前清空动画残影

	--无酒不欢：挨打时的掉血和状态显示
	if HitXYNum > 0 then
		local clips = {}
		for i = 0, HitXYNum - 1 do
			local dx = HitXY[i][1] - x0
			local dy = HitXY[i][2] - y0
			local hb = GetS(JY.SubScene, HitXY[i][1], HitXY[i][2], 4)		--海拔

			local ll = 4;
			for y=3, hnum do
				if HitXY[i][y] ~= nil then
					ll = string.len(HitXY[i][y]);
					break;
				end
			end
			local w = ll * CC.DefaultFont / 2 + 1
			clips[i] = {x1 = CC.XScale * (dx - dy) + CC.ScreenW / 2, y1 = CC.YScale * (dx + dy) + CC.ScreenH / 2 - hb, x2 = CC.XScale * (dx - dy) + CC.ScreenW / 2 + w, y2 = CC.YScale * (dx + dy) + CC.ScreenH / 2 + CC.DefaultFont + 1}
		end

		local clip = clips[0]
		for i = 1, HitXYNum - 1 do
			clip = MergeRect(clip, clips[i])
		end

		local area = (clip.x2 - clip.x1) * (clip.y2 - clip.y1)		--绘画的范围
		local surid = lib.SaveSur(minx, miny, maxx, maxy)		--绘画句柄

		--显示点数
		--无酒不欢：一次显示两种状态
		for y = 3, hnum-2, 2 do
			if JY.Restart == 1 then
				break
			end
			local flag = false;
			for i = 5, 15 do
				local tstart = lib.GetTime()
				local y_off = i * 2 + CC.DefaultFont + CC.RowPixel

				lib.SetClip(0, 0, CC.ScreenW, CC.ScreenH)
				lib.LoadSur(surid, minx, miny)
				for j = 0, HitXYNum - 1 do
					if HitXY[j][y] ~= nil or HitXY[j][y+1] ~= nil then
						local c = y - 1;
						--无酒不欢：这里用字符串的首位判定是否为掉血
						if y == 3 and HitXY[j][y] ~= nil and string.sub(HitXY[j][y],1,1) == "-" then
							if CONFIG.HPDisplay == 1 then
								HP_Display_When_Hit(i) --无酒不欢：实时显血
							end
							DrawString(clips[j].x1 - string.len(HitXY[j][y])*CC.DefaultFont/4, clips[j].y1 - y_off, HitXY[j][y], Color_Hurt1, CC.DefaultFont)
						else
							--无酒不欢：双排显示暂时这样写了
							local spacing = 0
							if HitXY[j][y] ~= nil then
								DrawString(clips[j].x1 - string.len(HitXY[j][y])*CC.DefaultFont/4, clips[j].y1 - y_off, HitXY[j][y], WAR.L_EffectColor[c], CC.DefaultFont)
								spacing = CC.DefaultFont
							end
							if HitXY[j][y+1] ~= nil then
								DrawString(clips[j].x1 - string.len(HitXY[j][y+1])*CC.DefaultFont/4, clips[j].y1 + spacing - y_off, HitXY[j][y+1], WAR.L_EffectColor[c+1], CC.DefaultFont)
							end
						end

						flag = true;
					end
				end

				if flag then
					ShowScreen(1)
					lib.SetClip(0, 0, 0, 0)
					local tend = lib.GetTime()
					if tend - tstart < CC.BattleDelay then
						lib.Delay(CC.BattleDelay - (tend - tstart))
					end
				end
			end
		end
		lib.FreeSur(surid)
	end

	--动画后恢复血条
	WAR.ShowHP = 1

	--清除点数
	for i = 0, HitXYNum - 1 do
		local id = GetWarMap(HitXY[i][1], HitXY[i][2], 2);
		WAR.Person[id]["生命点数"] = nil;
		WAR.Person[id]["内力点数"] = nil;
		WAR.Person[id]["体力点数"] = nil;
		WAR.Person[id]["中毒点数"] = nil;
		WAR.Person[id]["解毒点数"] = nil;
		WAR.Person[id]["内伤点数"] = nil;
		WAR.Person[id]["Life_Before_Hit"] = 0;
	end

	--清除特效文字
	for i = 0, WAR.PersonNum - 1 do
		WAR.Person[i]["特效动画"] = -1
		WAR.Person[i]["特效文字0"] = nil
		WAR.Person[i]["特效文字1"] = nil
		WAR.Person[i]["特效文字2"] = nil
		WAR.Person[i]["特效文字3"] = nil
		WAR.Person[i]["特效文字4"] = nil
	end
	lib.SetClip(0, 0, 0, 0)
	WarDrawMap(0)
	ShowScreen()
end


---执行医疗，解毒用毒暗器的子函数，自动医疗也可调用
function War_ExecuteMenu_Sub(x1, y1, flag, thingid)
	local pid = WAR.Person[WAR.CurID]["人物编号"]
	local x0 = WAR.Person[WAR.CurID]["坐标X"]
	local y0 = WAR.Person[WAR.CurID]["坐标Y"]
	CleanWarMap(4, 0)
	WAR.ShowHP = 0
	WAR.Person[WAR.CurID]["人方向"] = War_Direct(x0, y0, x1, y1)
	SetWarMap(x1, y1, 4, 1)
	local emeny = GetWarMap(x1, y1, 2)
	if emeny >= 0 then
		if flag == 1 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] then
			WAR.Person[emeny]["中毒点数"] = War_PoisonHurt(pid, WAR.Person[emeny]["人物编号"])
			SetWarMap(x1, y1, 4, 5)
			WAR.Effect = 5
		elseif flag == 2 and WAR.Person[WAR.CurID]["我方"] == WAR.Person[emeny]["我方"] then
			WAR.Person[emeny]["解毒点数"] = ExecDecPoison(pid, WAR.Person[emeny]["人物编号"])
			SetWarMap(x1, y1, 4, 6)
			WAR.Effect = 6
		elseif flag == 3 then
			--医生单独判定
			if WAR.Person[WAR.CurID]["人物编号"] == 0 and JY.Base["标准"] == 8 then

			elseif WAR.Person[WAR.CurID]["我方"] == WAR.Person[emeny]["我方"] then
			  WAR.Person[emeny]["生命点数"] = ExecDoctor(pid, WAR.Person[emeny]["人物编号"])
			  SetWarMap(x1, y1, 4, 4)
			  WAR.Effect = 4
			end
		--暗器
		elseif flag == 4 and WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[emeny]["我方"] then
			--葵花尊者反击暗器
			if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and WAR.Person[emeny]["人物编号"] == 27 then
				CleanWarMap(4, 0)
				local orid = WAR.CurID
				WAR.CurID = emeny

				WAR.Person[WAR.CurID]["人方向"] = War_Direct(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], x0, y0)

				Cls()
				local KHZZ = {"无知的"..JY.Person[0]["外号2"],"竟然想班门弄斧","吃我的葵花神针"}

				for i = 1, #KHZZ do
					lib.GetKey()
					DrawString(-1, -1, KHZZ[i], C_GOLD, CC.Fontsmall)
					ShowScreen()
					Cls()
					lib.Delay(1000)
				end

				SetWarMap(x0, y0, 4, 1)

				WAR.Person[orid]["生命点数"] = (WAR.Person[orid]["生命点数"] or 0) + AddPersonAttrib(WAR.Person[orid]["人物编号"], "生命", -300)
				WAR.Person[orid]["中毒点数"] = (WAR.Person[orid]["中毒点数"] or 0) + AddPersonAttrib(WAR.Person[orid]["人物编号"], "中毒程度", 100)
				WAR.TXXS[WAR.Person[orid]["人物编号"]] = 1

				WAR.KHSZ = 1

				War_ShowFight(WAR.Person[WAR.CurID]["人物编号"], 0, -1, 0, x0, y0, 35)

				WAR.KHSZ = 0

				WAR.CurID = orid
				return 1
			end
			if not match_ID(pid, 83) then
				--暗器随机伤害倍数
				WAR.AQBS = math.random(3)
				--袁承志用金蛇锥必定三倍
				if match_ID(pid, 54) and thingid == 30 then
					WAR.AQBS = 3
				end
				WAR.Person[emeny]["生命点数"] = War_AnqiHurt(pid, WAR.Person[emeny]["人物编号"], thingid, emeny)
				SetWarMap(x1, y1, 4, 2)
				WAR.Effect = 2
			end
		end
	end
	--主角医生方阵医疗
	if flag == 3 and pid == 0 and JY.Base["标准"] == 8 then
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if WAR.Person[WAR.CurID]["我方"] == WAR.Person[ep]["我方"] then
						WAR.Person[ep]["生命点数"] = ExecDoctor(pid, WAR.Person[ep]["人物编号"])
						SetWarMap(ex, ey, 4, 4)
						WAR.Effect = 4
					end
				end
			end
		end
	end
	--主角毒王方阵上毒，可以给自己上毒
	if flag == 1 and pid == 0 and JY.Base["标准"] == 9 then
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if (WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[ep]["我方"]) or ep == WAR.CurID then
						WAR.Person[ep]["中毒点数"] = War_PoisonHurt(pid, WAR.Person[ep]["人物编号"])
						SetWarMap(ex, ey, 4, 5)
						WAR.Effect = 5
					end
				end
			end
		end
	end
	--何铁手使用暗器为7*7方阵
	if flag == 4 and match_ID(pid, 83) then
		--暗器随机伤害倍数
		WAR.AQBS = math.random(3)
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if WAR.Person[WAR.CurID]["我方"] ~= WAR.Person[ep]["我方"] then
						WAR.Person[ep]["生命点数"] = War_AnqiHurt(pid, WAR.Person[ep]["人物编号"], thingid, ep)
						SetWarMap(ex, ey, 4, 4)
						WAR.Effect = 2
					end
				end
			end
		end
	end
	WAR.EffectXY = {}
	WAR.EffectXY[1] = {x1, y1}
	WAR.EffectXY[2] = {x1, y1}
	if flag == 1 then
		War_ShowFight(pid, 0, 0, 0, x1, y1, 30)
	elseif flag == 2 then
		War_ShowFight(pid, 0, 0, 0, x1, y1, 36)
	elseif flag == 3 then
		War_ShowFight(pid, 0, 0, 0, x1, y1, 0)
	elseif flag == 4 and (emeny >= 0 or match_ID(pid, 83)) then
		War_ShowFight(pid, 0, -1, 0, x1, y1, thingid)
	end
	--for i = 0, WAR.PersonNum - 1 do
		--WAR.Person[i]["点数"] = 0
	--end
	if flag == 4 then
		if emeny >= 0 or match_ID(pid, 83) then
			instruct_32(thingid, -1)
			return 1
		else
			return 0
		end
	else
		WAR.Person[WAR.CurID]["经验"] = WAR.Person[WAR.CurID]["经验"] + 1
		AddPersonAttrib(pid, "体力", -2)
	end

	if inteam(pid) then
		AddPersonAttrib(pid, "体力", -4)
	end
	return 1
end

--无酒不欢：挨打后，绘画动态集气条的判定
function DrawTimeBar2()
	local x1,x2,y = CC.ScreenW * 1 / 2 - 34, CC.ScreenW * 19 / 20 - 2, CC.ScreenH/10 + 29
	local draw = false

	--这三个是固定的，只需要加载一次就可以了
	--无酒不欢：这里也要判定是否有需要draw，如无需要则不加载
	local drawframe = false
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			if WAR.Person[i].TimeAdd < 0 then
				drawframe =  true
				break
			end
		end
	end
	if drawframe == true then
		DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
		DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
		DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
		lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
		lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
	end

	local surid = lib.SaveSur(x1 - (10 + (x2 - x1) / 2), 0, x2 + 10 + 20 + 30, y * 2 + 18 + 25)

	while true do
		if JY.Restart == 1 then
			break
		end
		draw = false
		for i = 0, WAR.PersonNum - 1 do
			local pid = WAR.Person[i]["人物编号"];
			--首先判定人物是否活着
			if WAR.Person[i]["死亡"] == false then
				--这里TimeAdd小于0代表集气位置要减少，数值为减少总量
				if WAR.Person[i].TimeAdd < 0 then
					draw = true
					--减量以20为单位循环增加，增加到超过0时，判定将不再成立，既停止减少集气位置
					WAR.Person[i].TimeAdd = WAR.Person[i].TimeAdd + 20
					if WAR.Person[i].TimeAdd > 0 then
						WAR.Person[i].TimeAdd = 0;
					end
					--如果人物的集气位置没有达到-500，则减少20，向-500靠近
					if WAR.Person[i].Time > -500 then
						--如果主运瑜伽，则不会低于300
						if Curr_NG(pid, 169) then
							if WAR.Person[i].Time > 300 then
								WAR.Person[i].Time = WAR.Person[i].Time - 20
								if WAR.Person[i].Time <= 300 then
									WAR.Person[i].Time = 300
									WAR.Person[i].TimeAdd = 0
								end
							end
						else
							WAR.Person[i].Time = WAR.Person[i].Time - 20
						end
					--如果人物的集气位置已经达到-500，则集气位置不再减少，而是转换为内伤
					else
						if JY.Person[pid]["受伤程度"] < 100 then
							AddPersonAttrib(pid, "受伤程度", math.random(3))
						end
					end
					if WAR.Person[i].Time <= -500 and PersonKF(pid, 100) then	--练了先天功后，当集气被杀到-500，内伤直接清0
						JY.Person[pid]["受伤程度"] = 0;
					end
				--大于0代表集气位置要增加，
				elseif WAR.Person[i].TimeAdd > 0 then
					draw = true
					--增量以20为单位循环减少，减少到低于0时，判定将不再成立，既停止增加集气位置
					WAR.Person[i].TimeAdd = WAR.Person[i].TimeAdd - 20
					--人物的集气位置以20为单位增加，如果集气位置超过995，则强制定为995
					WAR.Person[i].Time = WAR.Person[i].Time + 20
					if WAR.Person[i].Time > 995 then
						WAR.Person[i].Time = 995;
					end
				end
			end
		end

		if draw then
			lib.LoadSur(surid, x1 - (10 + (x2 - x1) / 2), 0)
			DrawTimeBar_sub(x1, x2, y, 1)
			ShowScreen()
			lib.Delay(8)
		else
			break;
		end
	end
	lib.Delay(100)
	lib.FreeSur(surid)
end

--绘制集气条
function DrawTimeBar()

	local x1,x2,y = CC.ScreenW * 1 / 2 - 34, CC.ScreenW * 19 / 20 - 2, CC.ScreenH/10 + 29
	local xunhuan = true

	--这三个是固定的，只需要加载一次就可以了
	DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
	DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
	DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
	lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
	lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)

	lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
	local surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)	--无酒不欢：修复杀到-500后集气条小头像刷新问题
	while xunhuan do
		if JY.Restart == 1 then
			break
		end
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["死亡"] == false then
				local jqid = WAR.Person[i]["人物编号"]
				local jq = WAR.Person[i].TimeAdd	--人物集气速度
				--无酒不欢：每25点内伤-1集气，每25点中毒-1集气，玩家与NPC一样
				local ns_factor = math.modf(JY.Person[jqid]["受伤程度"] / 25)
				local zd_factor = math.modf(JY.Person[jqid]["中毒程度"] / 25)
				--毒王中毒反而增加集气
				if jqid == 0 and JY.Base["标准"] == 9 then
					zd_factor = -(zd_factor*2)
				end
				--冰封也减少
				local bf_factor = 0;
				if JY.Person[jqid]["冰封程度"] >= 50 then
					bf_factor = 6
				elseif JY.Person[jqid]["冰封程度"] > 0 then
					bf_factor = 3
				end
				--何太冲的铁琴减少集气，一层减少1%
				local HTC_tq = 0
				if WAR.QYZT[jqid] ~= nil then
					HTC_tq = jq * 0.01 * WAR.QYZT[jqid]
				end
				--李秋水集气不受状态影响
				if match_ID(jqid, 118) == false then
					jq = jq - ns_factor - zd_factor - bf_factor - HTC_tq
				end
				if jq < 0 then
					jq = 0
				end
				if WAR.LQZ[jqid] == 100 then
					if Curr_QG(jqid,150) then	--运功瞬息千里，暴怒4倍集气
						jq = jq * 4
					else
						jq = jq * 3				--暴怒3倍集气
					end
				end
				--沉睡的敌人，无法集气
				if WAR.CSZT[jqid] == 1 then
					jq = 0
				--被无招胜有招击中的人，无法集气
				elseif WAR.WZSYZ[jqid] ~= nil then
					jq = 0
					WAR.WZSYZ[jqid] = WAR.WZSYZ[jqid] - 1
					if WAR.WZSYZ[jqid] < 1 then
						WAR.WZSYZ[jqid] = nil
					end
				--冻结的敌人，无法集气				
				elseif WAR.LRHF[jqid] ~= nil then
					jq = 0
					WAR.LRHF[jqid] = WAR.LRHF[jqid] - 1
					if WAR.LRHF[jqid] < 1 then
						WAR.LRHF[jqid] = nil
					end
				--没有封穴的情况下，可以集气
				elseif WAR.FXDS[jqid] == nil then
					--欧阳锋会跳气
					if match_ID(jqid, 60) and (math.random(10) == 8 or math.random(10) == 8) then
						jq = jq + math.random(10, 30);
					end
					if WAR.LSQ[jqid] ~= nil then	--被灵蛇拳击中，集气波动20时序
						if math.random(3) == 1 then
							WAR.Person[i].Time = WAR.Person[i].Time - jq
						else
							WAR.Person[i].Time = WAR.Person[i].Time + jq
						end
						WAR.LSQ[jqid] = WAR.LSQ[jqid] - 1
						if WAR.LSQ[jqid] == 0 then
							WAR.LSQ[jqid] = nil
						end
					else
						WAR.Person[i].Time = WAR.Person[i].Time + jq
					end
				--被封穴的话，不会集气，时序减少封穴
				else
					WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1

					--易筋经 封穴回复+1
					if PersonKF(jqid, 108) then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end

					--先天+玉女，封穴回复+1
					if PersonKF(jqid, 100) and PersonKF(jqid, 154) then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end

					--九阳7时序解除封穴
					--阳内主运或者阳罡学会九阳后
					if Curr_NG(jqid, 106) and (JY.Person[jqid]["内力性质"] == 1 or (jqid == 0 and JY.Base["标准"] == 6)) then
						if WAR.JYFX[jqid] == nil then
							WAR.JYFX[jqid] = 1;
						elseif WAR.JYFX[jqid] < 7 then
							WAR.JYFX[jqid] = WAR.JYFX[jqid] + 1;
						else
							WAR.JYFX[jqid] = nil;
							WAR.FXDS[jqid] = 0;
						end
					end

					--暴怒时解穴速度加倍
					if WAR.LQZ[jqid] == 100 then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end
					if WAR.FXDS[WAR.Person[i]["人物编号"]] < 1 then
						WAR.FXDS[WAR.Person[i]["人物编号"]] = nil
					end
				end

				--九阳神功回内
				--学会九阳并且是阳内或者天罡
				if PersonKF(jqid, 106) and (JY.Person[jqid]["内力性质"] == 1 or (jqid == 0 and JY.Base["标准"] == 6)) then
					JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] + 9
				end

				--九阴神功回血
				--学会九阴并且是阴内或者天罡
				if PersonKF(jqid, 107) and (JY.Person[jqid]["内力性质"] == 0 or (jqid == 0 and JY.Base["标准"] == 6)) then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + 2
				end

				--九阴额外回血
				--阴内主运或者阴罡学会九阴后
				if Curr_NG(jqid, 107) and (JY.Person[jqid]["内力性质"] == 0 or (jqid == 0 and JY.Base["标准"] == 6)) and inteam(jqid) then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + 2
				end

				--先天功回血回内
				if PersonKF(jqid, 100) then
					JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] + 4
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + 2
				end

				--易筋经回内
				if PersonKF(jqid, 108) then
					JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] + 6
				end

				
				--JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] - 100 + JY.Person[jqid]["体力"]
				--[[我方运功时，内力低于500，停运
				if JY.Person[jqid]["主运内功"] > 0 and JY.Person[jqid]["内力"] < 500 and inteam(jqid) then
					JY.Person[jqid]["主运内功"] = 0
				end

				--运功时，体力低于10，停运
				if JY.Person[jqid]["主运内功"] > 0 and JY.Person[jqid]["体力"] < 10 and inteam(jqid) then
					JY.Person[jqid]["主运内功"] = 0
				end

				--我方运功耗内
				if JY.Person[jqid]["主运内功"] > 0 and inteam(jqid) then
					--主运天内
					if JY.Person[jqid]["主运内功"] == JY.Person[jqid]["天赋内功"] then
						--队友耗6，主角不耗
						if jqid ~= 0 then
							JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] - 6
						end
					--非主运天内，耗9
					else
						JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] - 9
					end
				end]]

				--阿紫曼珠沙华，每时序掉1%血
				if match_ID(jqid, 47) and WAR.JYZT[jqid]~=nil then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] - math.modf(JY.Person[jqid]["生命最大值"]*0.01)
					if JY.Person[jqid]["生命"] < 1 then
						JY.Person[jqid]["生命"] = 0
						WAR.Person[WAR.CurID]["死亡"] = true
						WarSetPerson()
						Cls()
						ShowScreen()
						break
					end
				end

				--引燃：每时序损失1%当前血量
				if WAR.JHLY[jqid] ~= nil then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] - math.modf(JY.Person[jqid]["生命"]*0.01)

					if JY.Person[jqid]["生命"] < 1 then
						JY.Person[jqid]["生命"] = 1
					end
					WAR.JHLY[jqid] = WAR.JHLY[jqid] - 1

					if WAR.JHLY[jqid] < 1 then
						WAR.JHLY[jqid] = nil
					end
				end

				--灭绝的玉石俱焚，100时序
				if WAR.YSJF[jqid] ~= nil then
					WAR.YSJF[jqid] = WAR.YSJF[jqid] - 1

					if WAR.YSJF[jqid] < 1 then
						WAR.YSJF[jqid] = nil
					end
				end

				--被破军打中的敌人，内功停运50时序
				if WAR.PJZT[jqid] ~= nil then
					WAR.PJZT[jqid] = WAR.PJZT[jqid] - 1
					if WAR.PJZT[jqid] < 1 then
						WAR.PJZT[jqid] = nil
						JY.Person[jqid]["主运内功"] = WAR.PJJL[jqid]
						WAR.PJJL[jqid] = nil
					end
				end

				--混乱状态，解除后，敌人状态恢复
				if WAR.HLZT[jqid] ~= nil then
					WAR.HLZT[jqid] = WAR.HLZT[jqid] - 1
					if WAR.HLZT[jqid] < 1 then
						WAR.HLZT[jqid] = nil
						WAR.Person[i]["我方"] = false
					end
				end

				--虚弱状态
				if WAR.XRZT[jqid] ~= nil then
					WAR.XRZT[jqid] = WAR.XRZT[jqid] - 1
					if WAR.XRZT[jqid] < 1 then
						WAR.XRZT[jqid] = nil
					end
				end

				--无酒不欢：主运蛤蟆功时序增加怒气
				if Curr_NG(jqid, 95) then
					if WAR.LQZ[jqid] == nil then
						WAR.LQZ[jqid] = 1
					elseif WAR.LQZ[jqid] < 100 then
						WAR.LQZ[jqid] = WAR.LQZ[jqid] + 1
						if WAR.LQZ[jqid] == 100 then
							--东方不败，葵花秘法·化凤为凰
							local s = WAR.CurID
							local say = "怒气爆发"
							local ani_num = 6
							WAR.CurID = i
							if match_ID(jqid, 27) then
								say = "葵花秘法·化凤为凰"
								ani_num = 7
							end
							Cls()
							lib.SetClip(0, CC.ScreenH/4 + 20, CC.ScreenW, CC.ScreenH)
							CurIDTXDH(WAR.CurID, ani_num, 1, say)
							WAR.CurID = s
							--恢复之前的画面
							DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
							DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
							DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
							lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
							lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
							lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
							surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						end
					end
				end

				--无酒不欢：萧远山时序增加怒气
				if match_ID(jqid, 112) then
					if WAR.LQZ[jqid] == nil then
						WAR.LQZ[jqid] = 2
					elseif WAR.LQZ[jqid] < 100 then
						WAR.LQZ[jqid] = WAR.LQZ[jqid] + 2
						if WAR.LQZ[jqid] >= 100 then
							WAR.LQZ[jqid] = 100
							local s = WAR.CurID
							WAR.CurID = i
							Cls()
							lib.SetClip(0, CC.ScreenH/4 + 20, CC.ScreenW, CC.ScreenH)
							CurIDTXDH(WAR.CurID, 6, 1, "怒气爆发")
							WAR.CurID = s
							--恢复之前的画面
							DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
							DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
							DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
							lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
							lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
							lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
							surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						end
					end
				end

				--天山童姥：转瞬红颜
				if match_ID(jqid, 117) then
					if WAR.ZSHY[jqid] == nil then
						WAR.ZSHY[jqid] = 1
					else
						WAR.ZSHY[jqid] = WAR.ZSHY[jqid] + 1
					end
					if WAR.ZSHY[jqid] == 100 then
						WAR.ZSHY[jqid] = nil
						local s = WAR.CurID
						WAR.CurID = i
						Cls()
						lib.SetClip(0, CC.ScreenH/4 + 20, CC.ScreenW, CC.ScreenH)
						CurIDTXDH(WAR.CurID, 104, 1, "红颜弹指老·刹那芳华", PinkRed)
						WAR.CurID = s
						--恢复之前的画面
						DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
						DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
						DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
						lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
						lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
						lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						JY.Person[jqid]["生命"] = JY.Person[jqid]["生命最大值"]
						JY.Person[jqid]["内力"] = JY.Person[jqid]["内力最大值"]
						JY.Person[jqid]["体力"] = 100
						JY.Person[jqid]["中毒程度"] = 0
						JY.Person[jqid]["受伤程度"] = 0
						JY.Person[jqid]["冰封程度"] = 0
						JY.Person[jqid]["灼烧程度"] = 0
						--流血
						if WAR.LXZT[jqid] ~= nil then
							WAR.LXZT[jqid] = nil
						end
						--封穴
						if WAR.FXDS[jqid] ~= nil then
							WAR.FXDS[jqid] = nil
						end
					end
				end

				--[[葵花尊者，恢复
				if WAR.ZDDH == 54 and JY.Person[27]["品德"] == 20 and WAR.MCRS == 1 and jqid == 27 then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + 5
					JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] + 10
					JY.Person[jqid]["体力"] = JY.Person[jqid]["体力"] + 1
					JY.Person[jqid]["中毒程度"] = JY.Person[jqid]["中毒程度"] - 1
					JY.Person[jqid]["受伤程度"] = JY.Person[jqid]["受伤程度"] - 1
					JY.Person[jqid]["冰封程度"] = JY.Person[jqid]["冰封程度"] - 1
					JY.Person[jqid]["灼烧程度"] = JY.Person[jqid]["灼烧程度"] - 1
					--流血
					if WAR.LXZT[jqid] ~= nil then
						WAR.LXZT[jqid] = WAR.LXZT[jqid] - 1
					end
					--封穴
					if WAR.FXDS[jqid] ~= nil then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end
				end

				--主角医生回血内，减内伤，减中毒
				if jqid == 0 and JY.Base["标准"] == 8 then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + math.random(5);
					JY.Person[jqid]["内力"] = JY.Person[jqid]["内力"] + math.random(5);
					JY.Person[jqid]["中毒程度"] = JY.Person[jqid]["中毒程度"] - math.random(5);
					JY.Person[jqid]["受伤程度"] = JY.Person[jqid]["受伤程度"] - math.random(5);
				end

				--毒王时序增加中毒
				if jqid == 0 and JY.Base["标准"] == 9 then
					JY.Person[jqid]["中毒程度"] = JY.Person[jqid]["中毒程度"] + math.random(5)
					if JY.Person[jqid]["中毒程度"] > 100 then
						JY.Person[jqid]["中毒程度"] = 100
					end
				end]]

				--轻云蔽月时序计数
				if WAR.QYBY[jqid] ~= nil then
					WAR.QYBY[jqid] = WAR.QYBY[jqid] - 1
					if WAR.QYBY[jqid] < 1 then
						WAR.QYBY[jqid] = nil
					end
				end

				--进阶泰山，使用后20时序内闪避
				if WAR.TSSB[jqid] ~= nil then
					WAR.TSSB[jqid] = WAR.TSSB[jqid] - 1
					if WAR.TSSB[jqid] < 1 then
						WAR.TSSB[jqid] = nil
					end
				end

				--无明业火状态，耗损使用的内力一半的生命，30时序
				if WAR.WMYH[jqid] ~= nil then
					WAR.WMYH[jqid] = WAR.WMYH[jqid] - 1
					if WAR.WMYH[jqid] < 1 then
						WAR.WMYH[jqid] = nil
					end
				end

				--蓝烟清：王难姑指令，按时序中毒
				if WAR.L_WNGZL[jqid] ~= nil and WAR.L_WNGZL[jqid] > 0 then
					JY.Person[jqid]["中毒程度"] = JY.Person[jqid]["中毒程度"] + 1
					WAR.L_WNGZL[jqid] = WAR.L_WNGZL[jqid] -1;

					if WAR.L_WNGZL[jqid] <= 0 then
						WAR.L_WNGZL[jqid] = nil;
					end
				end

				--brolycjw：胡青牛指令，每个时序回复1%血
				if WAR.L_HQNZL[jqid] ~= nil and WAR.L_HQNZL[jqid] > 0 then
					JY.Person[jqid]["生命"] = JY.Person[jqid]["生命"] + math.modf(JY.Person[jqid]["生命最大值"]/100);
					if JY.Person[jqid]["受伤程度"] > 50 then
						JY.Person[jqid]["受伤程度"] = JY.Person[jqid]["受伤程度"] - 2;
					else
						JY.Person[jqid]["受伤程度"] = JY.Person[jqid]["受伤程度"] - 1;
					end
					WAR.L_HQNZL[jqid] = WAR.L_HQNZL[jqid] -1;
					if WAR.L_HQNZL[jqid] <= 0 then
						WAR.L_HQNZL[jqid] = nil;
					end
				end

				--无酒不欢：集气读数获取位置
				WAR.JQSDXS[jqid] = jq

				if WAR.Person[i].Time >= 1000 then
					if WAR.ZYHB == 1 then
						if i ~= WAR.ZYHBP then
							WAR.Person[i].Time = 990
						else
							WAR.Person[i].Time = 1001
						end
					end
					xunhuan = false
				end
			end
		end

		local warStatus = War_isEnd2()   --战斗是否结束？   0继续，1赢，2输
		if 0 < warStatus then
			break;
		end

		DrawTimeBar_sub(x1, x2, nil, 0)
		ShowScreen(1)
		WAR.SXTJ = WAR.SXTJ + 1
		--无酒不欢：三时序，五时序，六时序，九时序的计数器
		WAR.SSX_Counter = WAR.SSX_Counter + 1
		if WAR.SSX_Counter == 4 then
			WAR.SSX_Counter = 1
		end
		WAR.WSX_Counter = WAR.WSX_Counter + 1
		if WAR.WSX_Counter == 6 then
			WAR.WSX_Counter = 1
		end
		WAR.LSX_Counter = WAR.LSX_Counter + 1
		if WAR.LSX_Counter == 7 then
			WAR.LSX_Counter = 1
		end
		WAR.JSX_Counter = WAR.JSX_Counter + 1
		if WAR.JSX_Counter == 10 then
			WAR.JSX_Counter = 1
		end
		lib.Delay(10) -- 无酒不欢：减缓集气条速度	

		--集气过程中按空格或回车停止自动
		local keypress = lib.GetKey()
		if (keypress == VK_SPACE or keypress == VK_RETURN) then
			if WAR.AutoFight == 1 then
				WAR.AutoFight = 0
			end
		end

		lib.LoadSur(surid, x1 - ((x2 - x1) / 2)-100, 0)	--无酒不欢：修复杀到-500后集气条小头像刷新问题
	end

	--时序结束结算
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["死亡"] == false then
			WAR.Person[i].TimeAdd = 0
			local jqid=WAR.Person[i]["人物编号"]

			--判断是否在正常数据范围之内
			if JY.Person[jqid]["中毒程度"] < 0 then
				JY.Person[jqid]["中毒程度"] = 0;
			end
			if JY.Person[jqid]["受伤程度"] < 0 then
				JY.Person[jqid]["受伤程度"] = 0;
			end
			if JY.Person[jqid]["冰封程度"] < 0 then
				JY.Person[jqid]["冰封程度"] = 0;
			end
			if JY.Person[jqid]["灼烧程度"] < 0 then
				JY.Person[jqid]["灼烧程度"] = 0;
			end
			if JY.Person[jqid]["内力最大值"] < JY.Person[jqid]["内力"] then
				JY.Person[jqid]["内力"] = JY.Person[jqid]["内力最大值"]
			end
			if JY.Person[jqid]["生命最大值"] < JY.Person[jqid]["生命"] then
				JY.Person[jqid]["生命"] = JY.Person[jqid]["生命最大值"]
			end
			if JY.Person[jqid]["体力"] > 100 then
				JY.Person[jqid]["体力"] = 100
			end
		end
	end

	WAR.ZYHBP = -1
	lib.SetClip(0, 0, 0, 0)
	lib.FreeSur(surid)
end

--绘画整体集气条
function DrawTimeBar_sub(x1, x2, y, flag)

	--无酒不欢：绘画部分增加破绽区显示
	if not x2 then
		x2 = CC.ScreenW * 19 / 20 - 2
	end
	if not y then
		y = CC.ScreenH/10 + 29
	end
	if not x1 then
		x1 = CC.ScreenW * 1 / 2 - 34
		DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
		DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
		DrawString(x2 + 10, y - 20, "时序", C_WHITE, CC.FontSMALL)
		lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
		lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
	end

	for i = 0, WAR.PersonNum - 1 do
		if not WAR.Person[i]["死亡"] then
			--无酒不欢：修正集气条显示，不会飞过1000
			if WAR.Person[i].Time > 1001 then
				WAR.Person[i].Time = 1001
			end
			local id = WAR.Person[i]["人物编号"]
			local cx = x1 + math.modf(WAR.Person[i].Time*(x2 - x1)/1000)
			local headid = WAR.tmp[5000+i];
			if headid == nil then
				headid = JY.Person[id]["头像代号"]
			end
			local w, h = limitX(CC.ScreenW/25,12,35),limitX(CC.ScreenW/25,12,35)
			local jq_color = C_WHITE
			if JY.Person[id]["中毒程度"] == 100 then
				jq_color = RGB(56, 136, 36)
			elseif JY.Person[id]["中毒程度"] >= 50 then
				jq_color = RGB(120, 208, 88)
			end
			if WAR.LQZ[id] == 100 then
				jq_color = C_RED
			end
			if WAR.Person[i]["我方"] then
				drawname(cx, 1, id, CC.FontSmall)
				lib.LoadPNG(99, headid*2, cx - w / 2, y - h - 4, 1, 0)
				DrawString(cx-21, y-10-9, string.format("%3d",WAR.JQSDXS[id]), jq_color, CC.FontSMALL)	--集气速度
				if JY.Person[id]["灼烧程度"] ~= 0 then
					DrawString(cx, y-10-33, string.format("%3d",JY.Person[id]["灼烧程度"]), C_ORANGE, CC.FontSMALL)	--灼烧数值
				end
				if WAR.FXDS[id] ~= nil and WAR.FXDS[id] ~= 0 then
					DrawString(cx-21, y-10-33, string.format("%3d",WAR.FXDS[id]), C_GOLD, CC.FontSMALL)	--封穴数值
				end
			else
				drawname(cx, y+h, id, CC.FontSmall)
				lib.LoadPNG(99, headid*2, cx - w / 2, y + 6, 1, 0)
				DrawString(cx-21, y+h-9, string.format("%3d",WAR.JQSDXS[id]), jq_color, CC.FontSMALL)	--集气速度
				if JY.Person[id]["灼烧程度"] ~= 0 then
					DrawString(cx, y+h-33, string.format("%3d",JY.Person[id]["灼烧程度"]), C_ORANGE, CC.FontSMALL)	--灼烧数值
				end
				if WAR.FXDS[id] ~= nil and WAR.FXDS[id] ~= 0 then
					DrawString(cx-21, y+h-33, string.format("%3d",WAR.FXDS[id]), C_GOLD, CC.FontSMALL)	--封穴数值
				end
			end
		end
	end
	DrawString(x2 + 10, y , WAR.SXTJ, C_GOLD, CC.FontSMALL)
end

--绘画集气条上的名字
function drawname(x, y, id, size)
	local name = JY.Person[id]["姓名"]
	local color = C_WHITE
	--名字颜色随冰封和内伤变化
	if JY.Person[id]["受伤程度"] > JY.Person[id]["冰封程度"] then
		if JY.Person[id]["受伤程度"] > 99 then
			color = RGB(232, 32, 44)
		elseif JY.Person[id]["受伤程度"] > 66 then
			color = RGB(244, 128, 32)
		elseif JY.Person[id]["受伤程度"] > 33 then
			color = RGB(236, 200, 40)
		end
	else
		if JY.Person[id]["冰封程度"] >= 50 then
			color = M_RoyalBlue
		elseif JY.Person[id]["冰封程度"] > 0 then
			color = LightSkyBlue
		end
	end
	x = x - math.modf(size / 2)
	local namelen = string.len(name) / 2
	local zi = {}
	for i = 1, namelen do
		zi[i] = string.sub(name, i * 2 - 1, i * 2)
		DrawString(x, y, zi[i], color, size)
		y = y + size
	end
end

--判断两人之间的距离
function RealJL(id1, id2, len)
	if not len then
		len = 1
	end
	local x1, y1 = WAR.Person[id1]["坐标X"], WAR.Person[id1]["坐标Y"]
	local x2, y2 = WAR.Person[id2]["坐标X"], WAR.Person[id2]["坐标Y"]
	local s = math.abs(x1 - x2) + math.abs(y1 - y2)
	if len == nil then
		return s
	end
	if s <= len then
		return true
	else
		return false
	end
end

--武功范围
function WugongArea(wugong, level)
  --无酒不欢：参数说明
  --m1为移动范围斜向延伸：
	--0：延伸为直线距离-1，1：延伸至直线距离，2：延伸为0 3：移动范围固定为自身周围8格
  --m2为移动范围直线延伸；
	--数字即等于延伸距离
  --a1为攻击范围类型：
	--0：点攻，1：十字，2：菱形，3：面攻，5：十字，6：井字，7：田字，8：卍字，9：卐字，10：直线，11：正三角，12：倒三角，13：横线
  --a2为攻击范围长度距离：
	--0：点攻，大于0时，距离 = a2
	local m1, m2, a1, a2 = nil, nil, nil, nil
	if JY.Wugong[wugong]["攻击范围"] == -1 then
		return JY.Wugong[wugong]["加内力1"], JY.Wugong[wugong]["加内力2"], JY.Wugong[wugong]["未知1"], JY.Wugong[wugong]["未知2"], JY.Wugong[wugong]["未知3"], JY.Wugong[wugong]["未知4"], JY.Wugong[wugong]["未知5"]
	end
	--0：拳指
	--1：剑
	--2：刀
	--3：鞭
	--4：枪
	--5：自身
	local fightscope = JY.Wugong[wugong]["攻击范围"]
	local m3 = 0
	if fightscope == 0 then
		m1 = 0
		m2 = 1
		a1 = 0
		a2 = 0
	elseif fightscope == 1 then
		m1 = 0
		m2 = 2
		a1 = 0
		a2 = 0
		m3 = 1
	elseif fightscope == 2 then
		m1 = 2
		m2 = 3
		a1 = 0
		a2 = 0
		m3 = 1
	elseif fightscope == 3 then
		m1 = 0
		m2 = 2
		a1 = 0
		a2 = 0
	elseif fightscope == 4 then
		m1 = 0
		m2 = 3
		a1 = 0
		a2 = 0
		m3 = 1
	elseif fightscope == 5 then
		m1 = 0
		m2 = 0
		a1 = 0
		a2 = 0
	end

	return m1, m2, m3, a1, a2
end

--用CC表判断人物是否为队友，不管在不在队
function isteam(p)
	local r = false
	for i,v in pairs(CC.PersonExit) do
		if v[1] == p then
			r = true
			break;
		end
	end
	if p == 0 then
		r = true
	end
	return r;
end

--判断人物是否有某种武功
function NewPersonKF(p, kf)
	for i = 1, CC.Kungfunum do
		if JY.Person[p]["武功" .. i] <= 0 then
			return false;
		elseif JY.Person[p]["武功" .. i] == kf then
			return true
		end
	end
	return false
end

--老代码
function PersonKF(p, kf)
	return false
end

function PersonKFJ(p, kf)
	return false
end

--判断触发机率
function myrandom(p, id)
	--太玄神功+20
	if PersonKF(id, 102) then
		p = p + 20
	end
	--生命越低，几率越高，最多10
	p = p + math.modf((JY.Person[id]["生命最大值"]/JY.Person[id]["血量翻倍"] - JY.Person[id]["生命"]/JY.Person[id]["血量翻倍"])/100 + 1);

	--体力越高，几率越高，最多10
	p = p + math.modf(JY.Person[id]["体力"] / 10)

	--林朝英+10
	if match_ID(id, 605) then
		p = p + 10
	end

	--逆运走火+20
	if WAR.tmp[1000 + id] == 1 then
		p = p + 20
	end

	--每25点实战+1，上限20
	local jp = math.modf(JY.Person[id]["实战"] / 25 + 1)
	if jp > 20 then
		jp = 20
	end
	p = p + jp

	--每500内力+1，最多20
	p = p + limitX(math.modf(JY.Person[id]["内力"] / 500), 0, 20)

	--每50点攻击力+1，最多10
	p = p + limitX(math.modf(JY.Person[id]["攻击力"] / 50), 0, 10)

	--每50点防御力+1，最多10
	p = p + limitX(math.modf(JY.Person[id]["防御力"] / 50), 0, 10)

	--每50点轻功+1，最多10
	p = p + limitX(math.modf(JY.Person[id]["轻功"] / 50), 0, 10)

	--基础判定次数为一次
	local times = 1
	--如果是我方
	if inteam(id) then
		--我方天书增加几率
		p = p + JY.Base["天书数量"]
		--50%几率二次判定
		if math.random(2) == 2 then
			times = 2
		end
		--石破天必定二次判定
		if match_ID(id, 38) and times == 1 then
			times = 2
		end
	--NPC默认为三次判定且几率+60
	else
		times = 3
		p = p + 60
	end

	for i = 1, times do
		local bd = math.random(120)
		if bd <= p then
			return true
		end
	end
	return false
end


--自动选择敌人
function War_AutoSelectEnemy()
	local enemyid = War_AutoSelectEnemy_near()
	WAR.Person[WAR.CurID]["自动选择对手"] = enemyid
	return enemyid
end

--选择最近敌人
function War_AutoSelectEnemy_near(id)
	if id == nil then
		id = WAR.CurID
	end
	War_CalMoveStep(id, 100, 1)			--标记每个位置的步数
	local maxDest = math.huge
	local nearid = -1
	for i = 0, WAR.PersonNum - 1 do		--查找最近步数的敌人
		if WAR.Person[id]["我方"] ~= WAR.Person[i]["我方"] and WAR.Person[i]["死亡"] == false then
			local step = GetWarMap(WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"], 3)
			if step < maxDest then
				nearid = i
				maxDest = step
			end
		end
	end
	return nearid
end

--战斗中加入新人物
function NewWARPersonZJ(id, dw, x, y, life, fx)
	WAR.Person[WAR.PersonNum]["人物编号"] = id
	WAR.Person[WAR.PersonNum]["我方"] = dw
	WAR.Person[WAR.PersonNum]["坐标X"] = x
	WAR.Person[WAR.PersonNum]["坐标Y"] = y
	WAR.Person[WAR.PersonNum]["死亡"] = life
	WAR.Person[WAR.PersonNum]["人方向"] = fx
	WAR.Person[WAR.PersonNum]["贴图"] = WarCalPersonPic(WAR.PersonNum)
	lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[id]["头像代号"]), string.format(CC.FightPicFile[2], JY.Person[id]["头像代号"]), 4 + WAR.PersonNum)
	SetWarMap(x, y, 2, WAR.PersonNum)
	SetWarMap(x, y, 5, WAR.Person[WAR.PersonNum]["贴图"])
	WAR.PersonNum = WAR.PersonNum + 1
end

--无酒不欢：判定合击用的函数
function between(num_1, num_2, num_3, flag)
    if not flag then
		flag = 0
    end
    if num_3 < num_2 then
		num_2, num_3 = num_3, num_2
    end
    if flag == 0 and num_2 < num_1 and num_1 < num_3 then
		return true
    elseif flag == 1 and num_2 <= num_1 and num_1 <= num_3 then
		return true
    else
		return false
    end
end

--无酒不欢：独孤求败反击的伤害判定
function First_strike_dam_DG(pid, eid)
	local dam;
	local YJ_dif = (TrueYJ(pid)*2 - TrueYJ(eid))*5/1000
	dam = (JY.Person[pid]["攻击力"]*1.5-JY.Person[eid]["防御力"])+(JY.Person[pid]["武学常识"]*1.5-JY.Person[eid]["武学常识"])+(getnl(pid)/50*1.5-getnl(eid)/50)
	dam = math.modf(dam * YJ_dif)
	return dam
end

--伤害公式中的内力，当前内力和最大内力都参与计算
function getnl(id)
	return (JY.Person[id]["内力"] * 2 + JY.Person[id]["内力最大值"]) / 3
end

--无酒不欢：血量翻倍函数
function Health_in_Battle()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["人物编号"]
		--加一个变量避免重复翻倍
		if JY.Person[pid]["血量翻倍"] > 1 and WAR.HP_Bonus_Count[pid] == nil then
			JY.Person[pid]["生命最大值"] = JY.Person[pid]["生命最大值"] * JY.Person[pid]["血量翻倍"]
			JY.Person[pid]["生命"] = JY.Person[pid]["生命"] * JY.Person[pid]["血量翻倍"]
			WAR.HP_Bonus_Count[pid] = 1
		end
	end
end

--无酒不欢：血量还原函数
function Health_in_Battle_Reset()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["人物编号"]
		if JY.Person[pid]["血量翻倍"] > 1 and WAR.HP_Bonus_Count[pid] ~= nil then
			JY.Person[pid]["生命最大值"] = JY.Person[pid]["生命最大值"] / JY.Person[pid]["血量翻倍"]
			WAR.HP_Bonus_Count[pid] = nil
		end
	end
end

--无酒不欢：等待指令
function War_Wait()
	Cls()
  	CurIDTXDH(WAR.CurID, 72, 1, "伺机待发", LightGreen, 15)
	PushBack(WAR.CurID, 1)
	local id = WAR.Person[WAR.CurID]["人物编号"]
	WAR.Wait[id] = 1
  	return 1;
end

--无酒不欢：撤退
function War_Retreat()
	local id = WAR.Person[WAR.CurID]["人物编号"]
	local r = JYMsgBox(JY.Person[id]["姓名"], "确定要我撤退吗？", {"否","是"}, 2, WAR.tmp[5000+WAR.CurID])
	if r == 2 then
		WAR.Person[WAR.CurID]["死亡"] = true
		return 1;
	end
end

--无酒不欢：常态血条显示
function HP_Display_When_Idle()
    local x0 = WAR.Person[WAR.CurID]["坐标X"];
    local y0 = WAR.Person[WAR.CurID]["坐标Y"];
	for k = 0, WAR.PersonNum - 1 do
		local tmppid = WAR.Person[k]["人物编号"]
		if WAR.Person[k]["死亡"] == false then
			local dx = WAR.Person[k]["坐标X"] - x0
			local dy = WAR.Person[k]["坐标Y"] - y0

			local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

			local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
					ry = ry - hb - CC.YScale*7

			local pid = WAR.Person[k]["人物编号"]

			local Color = RGB(238,44, 44)
			--local Color1 = RGB(30, 144, 255)

			local HP_MAX = JY.Person[pid]["生命最大值"]

			local Current_HP = JY.Person[pid]["生命"]

			if Current_HP < 0 then
				Current_HP = 0
			end

			--友军NPC显示为绿色血条
			if WAR.Person[k]["我方"] == true then
				Color = RGB(0, 238, 0)
			end

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9,grey21)	--背景

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx-CC.XScale*1.4+(Current_HP/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --生命

			DrawBox3(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9, C_BLACK)
		end
	end
end

--无酒不欢：挨打掉血显示
function HP_Display_When_Hit(ssxx)
    local x0 = WAR.Person[WAR.CurID]["坐标X"];
    local y0 = WAR.Person[WAR.CurID]["坐标Y"];
	--掉血渐变显示			
	ssxx = ssxx - 4
	for k = 0, WAR.PersonNum - 1 do
		local tmppid = WAR.Person[k]["人物编号"]
		--血量有变化才显示
		if WAR.Person[k]["死亡"] == false and WAR.Person[k]["生命点数"] ~= nil and WAR.Person[k]["生命点数"] ~= 0 then
			local dx = WAR.Person[k]["坐标X"] - x0
			local dy = WAR.Person[k]["坐标Y"] - y0

			local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

			local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
					ry = ry - hb - CC.YScale*7

			local pid = WAR.Person[k]["人物编号"]

			local Color = RGB(238,44, 44)
			--local Color1 = RGB(30, 144, 255)

			--计算掉血
			local HP_MAX = JY.Person[pid]["生命最大值"]

			local HP_AfterHit = JY.Person[pid]["生命"]

			if HP_AfterHit < 0 then
				HP_AfterHit = 0
			end

			local HP_BeforeHit = WAR.Person[k]["Life_Before_Hit"] or 0

			local HP_Loss = HP_BeforeHit - HP_AfterHit

			local Gradual_HP_Loss;
			local Gradual_HP_Display;

			Gradual_HP_Loss = HP_Loss*(ssxx/11)
			Gradual_HP_Display = HP_BeforeHit - Gradual_HP_Loss


			--友军NPC显示为绿色血条
			if WAR.Person[k]["我方"] == true then
				Color = RGB(0, 238, 0)
			end

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9,grey21)	--背景

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx-CC.XScale*1.4+(HP_AfterHit/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --生命

			--掉血显示
			if HP_Loss > 0 then
				lib.FillColor(rx-CC.XScale*1.4+(HP_AfterHit/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*20/9, rx-CC.XScale*1.4+(Gradual_HP_Display/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --失去生命
			end

			DrawBox3(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9, C_BLACK)
		end
	end
end

--苍天泰坦：被战场显血函数调用
function DrawBox3(x1, y1, x2, y2, color)
	lib.DrawRect(x1, y1, x2, y1, color)
	lib.DrawRect(x1, y2, x2, y2, color)
	lib.DrawRect(x1, y1, x1, y2, color)
	lib.DrawRect(x2, y1, x2, y2, color)
	--无酒不欢：生命和内力的分隔线
	--lib.DrawRect(x1, y1+(y2-y1)/2+1, x2, y1+(y2-y1)/2+1, color)
end

--显示出招动画的选择出战人物界面
function WarSelectTeam_Enhance()
	if JY.Restart == 1 then
		do return end
	end
	local T_Num=GetTeamNum();
	--无酒不欢：高度以3为单位增加
	local h_factor = 3
	if T_Num > 12 then
		h_factor = 15
	elseif T_Num > 9 then
		h_factor = 12
	elseif T_Num > 6 then
		h_factor = 9
	elseif T_Num > 3 then
		h_factor = 6
	end
	local p={};
	local pic_w=CC.ScreenW/6--160;
	local pic_h=CC.ScreenW/6*3/4--128;
	local width=pic_w*3+CC.DefaultFont*5+4*8;
	local height=math.max((h_factor+2)*(CC.DefaultFont+4)+4*3,pic_h*math.modf((h_factor+1)/4))+CC.FontBig;
	local x=(CC.ScreenW-width)/2;
	local y=(CC.ScreenH-height-4*2)/2+CC.FontBig/2+8;
	local x0=x+4*4;
	local x1=x0+4;
	local y1=(CC.ScreenH-((T_Num+2)*(CC.DefaultFont+4)+4*3))/2;
	local x2=x0+4*3+CC.DefaultFont*5+pic_w/2
	local y2=y;
	local ts=(width-(CC.FontBig*4+16)*2)/3;
	local tx1=x+ts+4;
	local tx2=tx1+(CC.FontBig*4+16)+ts;
	local ty=y+pic_h+30+CC.DefaultFont;

	--单通模式
	if true then
		for i = 1, 6 do
			WAR.Data["自动选择参战人" .. i] = -1
		end
	end

	--剪裁的背景图
	--没有自动选择出战人时才显示
	--单挑陈达海战特殊判定
	if WAR.Data["自动选择参战人1"] == -1 and not (WAR.ZDDH == 92 and GetS(87,31,33,5) == 1) then
		Clipped_BgImg((CC.ScreenW - width) / 2,(CC.ScreenH - height) / 2,(CC.ScreenW + width) / 2,(CC.ScreenH + height) / 2,1000)
		Clipped_BgImg((CC.ScreenW - (CC.DefaultFont+4)*4) / 2,(CC.ScreenH - height) / 2-(CC.DefaultFont+4)/2,(CC.ScreenW + (CC.DefaultFont+4)*4) / 2,(CC.ScreenH - height) / 2+(CC.DefaultFont+4)/2,1000)
	end
	for i=1,T_Num do
		local pid=JY.Base["队伍"..i];
		if pid <0 then
			break;
		end

	  --冰糖恋：单挑陈达海
		if WAR.ZDDH == 92 and GetS(87,31,33,5) == 1 then
			WAR.Data["自动选择参战人1"] = 0;
			WAR.Data["我方X1"] = 33
			WAR.Data["我方Y1"] = 24
		end

		--战三渡，如果周芷若在队则周芷若必出战
		if WAR.ZDDH == 253 and inteam(631) then
			WAR.Data["手动选择参战人2"] = 631
		end

		--畅想杨过绝情谷两战
		if (WAR.ZDDH == 272 or WAR.ZDDH == 273) and JY.Base["畅想"] == 58 then
			WAR.Data["自动选择参战人2"] = 59
		end

		for i = 1, 6 do
			local id = WAR.Data["自动选择参战人" .. i]
			if id >= 0 then
				--畅想的情况，畅想主角会取代强制出战的队友
				if id == JY.Base["畅想"] then
					WAR.Person[WAR.PersonNum]["人物编号"] = 0
				else
					WAR.Person[WAR.PersonNum]["人物编号"] = id
				end
				WAR.Person[WAR.PersonNum]["我方"] = true
				WAR.Person[WAR.PersonNum]["坐标X"] = WAR.Data["我方X" .. i]
				WAR.Person[WAR.PersonNum]["坐标Y"] = WAR.Data["我方Y" .. i]
				WAR.Person[WAR.PersonNum]["死亡"] = false
				WAR.Person[WAR.PersonNum]["人方向"] = 2
				--无酒不欢：调整战斗初始面向
				--战海大富
				if WAR.ZDDH == 259 then
					WAR.Person[WAR.PersonNum]["人方向"] = 1
				end
				--双挑公孙止
				if WAR.ZDDH == 273 then
					WAR.Person[WAR.PersonNum]["人方向"] = 1
				end
				--杨过单金轮
				if WAR.ZDDH == 275 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--战杨龙
				if WAR.ZDDH == 75 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--蒙哥
				if WAR.ZDDH == 278 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--周芷若夺掌门
				if WAR.ZDDH == 279 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--单挑赵敏
				if WAR.ZDDH == 293 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--玄冥二老
				if WAR.ZDDH == 295 then
					WAR.Person[WAR.PersonNum]["人方向"] = 0
				end
				--三挑岳不群
				if WAR.ZDDH == 298 then
					WAR.Person[WAR.PersonNum]["人方向"] = 1
				end
				WAR.PersonNum = WAR.PersonNum + 1
			end
		end

		if WAR.PersonNum > 0 and WAR.ZDDH ~= 235 then
			return
		end

		lib.PicLoadFile(string.format(CC.FightPicFile[1],JY.Person[pid]["头像代号"]),
		string.format(CC.FightPicFile[2],JY.Person[pid]["头像代号"]), 4+i);
		local n=0;
		local m=0;
		for j=1,5 do
			if JY.Person[pid]['出招动画帧数'..j]>0 then
				if j>1 then
					m=j;
					break;
				end
				n=n+JY.Person[pid]['出招动画帧数'..j]
			end
		end
		p[i]= {id=pid, name=JY.Person[pid]["姓名"];
		Pic=n*8+JY.Person[pid]['出招动画帧数'..m]*6, PicNum=JY.Person[pid]['出招动画帧数'..m], idx=0,
		x=x2+((i+3)%4)*pic_w, y=y2+math.modf((i+3)/4)*pic_h, x=x2+((i+2)%3)*pic_w, y=y2+math.modf((i+2)/3)*pic_h, picked=0,
		};
		--无酒不欢：强制出战的队友
		for j = 1, 6 do
			if WAR.Data["手动选择参战人" .. j] == p[i].id then
				p[i].picked = 1
				WAR.MCRS = WAR.MCRS + 1
			end
		end
	end
	--现在所有都是3人
	WAR.MCRS = WAR.MCRS + 3
	--[[战三渡
	if WAR.ZDDH == 253 then
		WAR.MCRS = WAR.MCRS + 3
	end

	--逍遥御风 天池怪侠 太白诗仙 古墓黄杉 金蛇郎君
	--限定1人
	if WAR.ZDDH == 281 or WAR.ZDDH == 283 or WAR.ZDDH == 284 or WAR.ZDDH == 285 or WAR.ZDDH == 286 then
		WAR.MCRS = WAR.MCRS + 5
	end

	--刀剑合璧
	--限定2人
	if WAR.ZDDH == 280 then
		WAR.MCRS = WAR.MCRS + 4
	end]]

	p[0]={name="全部选择"};

	if T_Num>6 then
		p[0]={name="自动选择"}
	end

	p[T_Num+1]={name="开始战斗"};
	local leader=-1;
	--无酒不欢：强制出战的预设leader
	for i=1,T_Num do
		if p[i].picked == 1 then
			leader = i
			break
		end
	end
	DrawBoxTitle(width,height,'出战准备',C_ORANGE);
	local select=1;
	local sid=lib.SaveSur(0,0,CC.ScreenW,CC.ScreenH);
	local function redraw(zdrs)
		lib.LoadSur(sid,0,0);
		DrawBox(x0,y1,x0+CC.DefaultFont*5+4*2,y1+CC.DefaultFont*(T_Num+2)+4*(T_Num+3),C_WHITE);
		for i=0,T_Num+1 do
			local str=p[i].name;
			--选中时的名字显示
			--小于7人，名字前显示√表示已选择
			--大于等于7人，名字前显示×表示需要取消方可开始战斗
			if i > 0 and i < T_Num+1 and p[i].picked > 0 then
				if zdrs < 7 then
					str="√"..str;
				else
					str="×"..str
				end
			--未选中的只显示名字
			else
				str=" "..str;
			end
			if select==i then
				lib.Background(x1,y1+(CC.DefaultFont+4)*(i)+4,x1+CC.DefaultFont*5,y1+(CC.DefaultFont+4)*(i+1),128,C_ORANGE)
				DrawString(x1,y1+(CC.DefaultFont+4)*(i)+4,str,C_WHITE,CC.DefaultFont);
			elseif i>0 and i<=T_Num then
				DrawString(x1,y1+(CC.DefaultFont+4)*(i)+4,str,C_ORANGE,CC.DefaultFont);
			else
				DrawString(x1,y1+(CC.DefaultFont+4)*(i)+4,str,C_GOLD,CC.DefaultFont);
			end
		end
		for i=1,T_Num do
			local color;
			if p[i].picked > 0 then
				--DrawString(p[i].x-CC.DefaultFont,p[i].y-CC.DefaultFont/2,"出战",C_WHITE,CC.DefaultFont*2/3)
				color=C_WHITE;
				lib.PicLoadCache(4+i,p[i].Pic+p[i].idx*2,p[i].x,p[i].y)
				p[i].idx=p[i].idx+1;
				if p[i].idx>=p[i].PicNum then
					p[i].idx=0;
				end
			else
				color=M_Gray;
				lib.PicLoadCache(4+i,p[i].Pic,p[i].x,p[i].y)
				lib.PicLoadCache(4+i,p[i].Pic,p[i].x,p[i].y,6,180)
			end
		end
	end

	--local zdrs=0
	while true do
		if JY.Restart == 1 then
			break
		end
		redraw(WAR.MCRS);
		ShowScreen();
		lib.Delay(65);
		local k=lib.GetKey();
		if k==VK_UP then
			select=select-1;
		elseif k==VK_DOWN then
			select=select+1;
		elseif k==VK_SPACE or k==VK_RETURN then
			if select==0 then
				if p[0].name=="全部选择" or p[0].name=="自动选择" then
					local zrs=T_Num
					if zrs>6 then
						zrs=6
					end
					for i=1,zrs do
						if p[i].picked == 0 then
							p[i].picked=2;
							WAR.MCRS=WAR.MCRS+1
						end
					end
					if leader<0 then
						leader=1;
					end
					p[0].name="全部取消";
				elseif p[0].name=="全部取消" then
					for i=1,T_Num do
						if p[i].picked == 2 then
							p[i].picked=0;
							WAR.MCRS=WAR.MCRS-1
						end
					end
					leader=-1;
					--无酒不欢：强制出战的预设leader
					for i=1,T_Num do
						if p[i].picked == 1 then
							leader = i
							break
						end
					end
					p[0].name="全部选择"

					if T_Num>6 then
						p[0].name="自动选择"
					end
				end
			elseif select==T_Num+1 then
				if leader<0 then
					select=1;
				elseif WAR.MCRS>6 then
					select=1
				else
					local px={}
					local wz=0
					for i=1,T_Num do
						if p[i].picked > 0 then
							wz=wz+1
							px[wz]=i
						end
					end

					for i=1,wz do
						if px[i]~=nil then
							WAR.Person[WAR.PersonNum]["人物编号"]=JY.Base["队伍" ..px[i]]
							WAR.Person[WAR.PersonNum]["我方"]=true
							WAR.Person[WAR.PersonNum]["坐标X"]=WAR.Data["我方X"..i]
							WAR.Person[WAR.PersonNum]["坐标Y"]=WAR.Data["我方Y"..i]
							WAR.Person[WAR.PersonNum]["死亡"]=false
							WAR.Person[WAR.PersonNum]["人方向"]=2
							--无酒不欢：调整战斗初始面向
							--战海大富
							if WAR.ZDDH == 259 then
								WAR.Person[WAR.PersonNum]["人方向"] = 1
							end
							--双挑公孙止
							if WAR.ZDDH == 273 then
								WAR.Person[WAR.PersonNum]["人方向"] = 1
							end
							--杨过单金轮
							if WAR.ZDDH == 275 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--战杨龙
							if WAR.ZDDH == 75 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--蒙哥
							if WAR.ZDDH == 278 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--周芷若夺掌门
							if WAR.ZDDH == 279 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--单挑赵敏
							if WAR.ZDDH == 293 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--玄冥二老
							if WAR.ZDDH == 295 then
								WAR.Person[WAR.PersonNum]["人方向"] = 0
							end
							--三挑岳不群
							if WAR.ZDDH == 298 then
								WAR.Person[WAR.PersonNum]["人方向"] = 1
							end
							WAR.PersonNum=WAR.PersonNum+1
						end
					end
					break;
				end
			else
				if p[select].picked == 2 then
					p[select].picked=0;
					WAR.MCRS=WAR.MCRS-1
					if leader==select then
						leader=-1;
						for i=1,T_Num do
							if p[i].picked > 0 then
								leader=i;
								break;
							end
						end
					end
					if leader==-1 then
						p[0].name="全部选择"

						if T_Num>6 then
							p[0].name="自动选择"
						end
					end
				elseif p[select].picked == 0 then
					p[select].picked=2;
					WAR.MCRS=WAR.MCRS+1
					if leader<0 then
						leader=select;
					end
					for i=1,T_Num do
						if p[i].picked == 0 then
							break;
						end
						if i==T_Num then
							p[0].name="全部取消";
						end
					end
				end
			end
		end
		if select<0 then
			select=T_Num+1;
		elseif select>T_Num+1 then
			select=0;
		end
	end
	lib.FreeSur(sid);
end

--葵花魅影
function kuihuameiying()
	local x, y
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["人物编号"] == 0 then
			x, y = WAR.Person[i]["坐标X"], WAR.Person[i]["坐标Y"]
			break
		end
	end
	local function vacant(x,y)
		local r = true
		if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
			r = false
	    elseif CC.SceneWater[lib.GetWarMap(x, y, 0)] ~= nil then
	       	r = false
	    end
		if x < 1 or x > 63 then
			r = false
		end
		if y < 1 or y > 63 then
			r = false
		end
		return r
	end
	local telx, tely = 0, 0
	local can_tele = 0
	for i = -3, 3 do
		for j = -3, 3 do
			if vacant(x+i,y+j) then
				telx, tely = x+i, y+j
				can_tele = 1
			end
		end
	end
	if can_tele == 1 then
		WarDrawMap(0)
		CurIDTXDH(WAR.CurID, 120, 1, "葵花魅影", C_GOLD)
		lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, -1)
		lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, -1)
		WarDrawMap(0)
		WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"] = telx, tely
		WarDrawMap(0)
		CurIDTXDH(WAR.CurID, 120, 1, "葵花魅影", C_GOLD)
		lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 5, WAR.Person[WAR.CurID]["贴图"])
		lib.SetWarMap(WAR.Person[WAR.CurID]["坐标X"], WAR.Person[WAR.CurID]["坐标Y"], 2, WAR.CurID)
		WarDrawMap(0)
		return true
	else
		return false
	end
end

function NeiLiDamage(pid, dmg)
	if JY.Person[pid]["体力"] == 0 then
		dmg = dmg * 2
	end
	local neili = JY.Person[pid]["内力"]
	if neili >= dmg then
		JY.Person[pid]["内力"] = JY.Person[pid]["内力"] - dmg
	else
		WAR.Person[WAR.CurID]["生命点数"] = AddPersonAttrib(pid, "生命", - 2 * dmg + 2 * JY.Person[pid]["内力"]);
		JY.Person[pid]["内力"] = 0
		Cls();
		War_Show_Count(WAR.CurID, "油尽灯枯气血流失");
	end
end

--辟邪招式
function BiXieZhaoShi(id,MiaofaWX)
	WAR.BXZS = 0
	if not WAR.BXLQ[id] then
		WAR.BXLQ[id] = {0,0,0,0,0,0}
	end
	local zs={
	{name="指打奸邪",Usable=true,m1=1,m2=1,a1=1,a2=3+MiaofaWX,a3=3+MiaofaWX},
	{name="飞燕穿柳",Usable=true,m1=3,m2=1,a1=10,a2=8+MiaofaWX,a3=7+MiaofaWX,a4=6+MiaofaWX},
	{name="花开见佛",Usable=true,m1=0,m2=0,a1=5,a2=6+MiaofaWX,a3=3+MiaofaWX},
	{name="锺馗抉目",Usable=true,m1=0,m2=5,a1=2,a2=4+MiaofaWX},
	{name="扫荡群魔",Usable=true,m1=3,m2=1,a1=11,a2=6+MiaofaWX},
	{name="紫气东来",Usable=true,m1=0,m2=6,a1=3,a2=3+MiaofaWX,a3=3+MiaofaWX},
	}
	local size = CC.DefaultFont
	local surid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)
	local m1, m2, a1, a2, a3, a4, a5
	local choice = 1
	if not PersonKF(id,105) then
		for i = 3, 6 do
			zs[i].Usable=false
		end
	end
	while true do
		if JY.Restart == 1 then
			break
		end
		Cls()
		for i = 1, #zs do
			lib.LoadPNG(1, 997 * 2 , 510, 118+i*50, 1)
			local color = C_WHITE
			if WAR.BXLQ[id][i] > 0 then
				zs[i].Usable=false
			end
			if zs[i].Usable==false then
				color = M_Gray
				if i == choice then
					DrawString(680, 122+i*50, "X", C_RED, size)
				end
			end
			if i == choice then
				color = C_GOLD
			end
			DrawString(520, 123+i*50, i, color, size*0.8)
			DrawString(551, 122+i*50, zs[i].name, color, size)
		end

		lib.LoadPNG(1, 996 * 2 , 480, 500, 1)
		DrawString(500, 520, "招式气攻："..CC.KFMove[48][choice][2], C_WHITE, size)
		if WAR.BXCD[choice] == 0 or match_ID(id, 36) then
			DrawString(500, 570, "冷却时间：无", C_WHITE, size)
		else
			DrawString(500, 570, "冷却时间："..WAR.BXCD[choice].."回合", C_WHITE, size)
		end
		if choice > 2 and not PersonKF(id,105) then
			DrawString(500, 620, "习得葵花神功后方可使用", C_WHITE, size)
		elseif WAR.BXLQ[id][choice] > 0 then
			DrawString(500, 620, "冷却中，"..WAR.BXLQ[id][choice].."回合后可再次使用", C_WHITE, size)
		end
		ShowScreen()

		local keyPress, ktype, mx, my = lib.GetKey()
		lib.Delay(CC.Frame)

		if keyPress==VK_SPACE or keyPress==VK_RETURN then
			if zs[choice].Usable then
				break
			end
		elseif keyPress == VK_UP then
			choice = choice - 1
			if choice < 1 then
				choice = #zs
			end
		elseif keyPress == VK_DOWN then
			choice = choice + 1
			if choice > #zs then
				choice = 1
			end
		elseif keyPress >= 49 and keyPress <= 57 then
			local input = keyPress - 48
			if input <= #zs and zs[input].Usable then
				choice = input
				break
			end
		end
	end
	WAR.BXZS = choice
	m1, m2, a1, a2, a3, a4, a5 = zs[choice].m1, zs[choice].m2, zs[choice].a1, zs[choice].a2, zs[choice].a3, zs[choice].a4, zs[choice].a5
	return m1, m2, a1, a2, a3, a4, a5
end