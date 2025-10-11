function Set_Eff_Text(id, txwz, str)
	if WAR.Person[id][txwz] ~= nil then
		WAR.Person[id][txwz] = WAR.Person[id][txwz].."+"..str
	else
		WAR.Person[id][txwz] = str
	end
end

--��������֮���ʵ�ʾ���
function War_realjl(ida, idb)
	if ida == nil then
		ida = WAR.CurID
	end
	CleanWarMap(3, 255)
	local x = WAR.Person[ida]["����X"]
	local y = WAR.Person[ida]["����Y"]
	local steparray = {}
	steparray[0] = {}
	steparray[0].bushu = {}
	steparray[0].x = {}
	steparray[0].y = {}
	SetWarMap(x, y, 3, 0)
	steparray[0].num = 1
	steparray[0].bushu[1] = 0		--�����ƶ��Ĳ���
	steparray[0].x[1] = x
	steparray[0].y[1] = y
	return War_FindNextStep1(steparray, 0, ida, idb)
end

--AIѡ��Ŀ��ĺ���
function AIThink(kfid)
	local pid = WAR.Person[WAR.CurID]["������"]
	local kungfuid = JY.Person[pid]["�书" .. kfid]
	local atkarray = {}
	local num = 0
	CleanWarMap(4, -1)
	local movearray = War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)
	WarDrawMap(1)
	ShowScreen()

	for i = 0, WAR.Person[WAR.CurID]["�ƶ�����"] do
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
	--lib.Debug(JY.Person[pid]["����"])
	--lib.Debug(atkarray[1].p)
	if atkarray[1].p > 0 then
		for i = 2, num do
			if atkarray[i].p == 0 or atkarray[i].p < atkarray[1].p / 2 then
				num = i - 1
				break;
			end
		end
		for i = 1, num do
			if WAR.Person[WAR.CurID]["�ҷ�"] == true then
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

		War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)
		War_MovePerson(atkarray[select].x, atkarray[select].y)
		War_Fight_Sub(WAR.CurID, kfid, atkarray[select].ax, atkarray[select].ay)
		--�����ṥ����㿪
		if pid == 606 then
			WAR.Person[WAR.CurID]["�ƶ�����"] = 10
			War_AutoEscape()
			War_RestMenu()
		end
	else
		--�������ߣ��򲻵��˻�˲��
		if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and pid == 27 and kuihuameiying() then
			AIThink(kfid)
		else
			--�򲻵��ˣ����ǳ�ҩ
			local jl, nx, ny = War_realjl()
			AutoMove()
			--Ĭ��Ϊ��Ϣ
			local what_to_do = 0
			local can_eat_drug = 0
			--[[���ҷ����ῼ�ǳ�ҩ
			if WAR.Person[WAR.CurID]["�ҷ�"] == false then
				can_eat_drug = 1
			--������ҷ���ֻ���ڶ�������Ż��ҩ
			else
				if inteam(pid) and JY.Person[pid]["�Ƿ��ҩ"] == 1 then
					can_eat_drug = 1
				end
			end]]
			--���ҵڶ��£����ܳ�ҩ
			if WAR.ZYHB == 2 then
				can_eat_drug = 0
			end
			--1:������ҩ 2����Ѫ 3��ҽ�� 4�������� 5���Խⶾ
			if can_eat_drug == 1 then
				local r = -1
				--��������10��������ҩ
				if JY.Person[pid]["����"] < 10 then
					r = War_ThinkDrug(4)
					if r >= 0 then
						what_to_do = 1
					end
				end
				local rate = -1
				if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 5 then
					rate = 90
				elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 4 then
					rate = 70
				elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 3 then
					rate = 50
				elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 2 then
					rate = 25
				end
				--����Ҳ���ӳ�Ѫҩ����
				if JY.Person[pid]["���˳̶�"] > 50 then
					rate = rate + 50
				end
				if Rnd(100) < rate then
					r = War_ThinkDrug(2)
					if r >= 0 then				--�����ҩ��ҩ
						what_to_do = 2
					else
						r = War_ThinkDoctor()		--���û��ҩ������ҽ��
						if r >= 0 then
							what_to_do = 3
						end
					end
				end
				--��������
				rate = -1
				if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 6 then
					rate = 100
				elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 5 then
					rate = 75
				elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 4 then
					rate = 50
				end
				if Rnd(100) < rate then
					r = War_ThinkDrug(3)
					if r >= 0 then
						what_to_do = 4
					end
				end
				rate = -1
				if CC.PersonAttribMax["�ж��̶�"] * 3 / 4 < JY.Person[pid]["�ж��̶�"] then
					rate = 60
				else
					if CC.PersonAttribMax["�ж��̶�"] / 2 < JY.Person[pid]["�ж��̶�"] then
						rate = 30
					end
				end
				--��Ѫ���£��ųԽⶾҩ
				if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 2 and Rnd(100) < rate then
					r = War_ThinkDrug(6)
					if r >= 0 then
						what_to_do = 5
					end
				end
			end
			--��ҩflag 2������ 3������ 4������ 6���ⶾ
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
	local enemyid = War_AutoSelectEnemy()   --ѡ���������

	War_CalMoveStep(WAR.CurID,100,0);   --�����ƶ����� �������100��

	for i=0,CC.WarWidth-1 do
		for j=0,CC.WarHeight-1 do
			local dest=GetWarMap(i,j,3);
			if dest <128 then
				local dx=math.abs(i-WAR.Person[enemyid]["����X"])
				local dy=math.abs(j-WAR.Person[enemyid]["����Y"])
				if minDest>(dx+dy) then        --��ʱx,y�Ǿ�����˵����·������Ȼ���ܱ�Χס
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

	if minDest < math.huge then   --��·����
	    while true do    --��Ŀ��λ�÷����ҵ������ƶ���λ�ã���Ϊ�ƶ��Ĵ���
			local i=GetWarMap(x,y,3);
			if i<=WAR.Person[WAR.CurID]["�ƶ�����"] then
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
		War_MovePerson(x,y);    --�ƶ�����Ӧ��λ��
	end
end

function GetMovePoint(x, y, flag)
	local point = 0
	local wofang = WAR.Person[WAR.CurID]["�ҷ�"]
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
						if WAR.Person[v]["�ҷ�"] == wofang then
							point = point + i * 2 - 26
						elseif WAR.Person[v]["�ҷ�"] ~= wofang then
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
	local pid = WAR.Person[warid]["������"]
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
		local eid = WAR.Person[mid]["������"]
		local dmg = War_PredictDamage(pid, eid, kungfuid)
		local ehp = JY.Person[eid]["����"]
		local rate = dmg * 1000 / ehp
		if rate > target.p then
			target.x = enemys[i].x + x
			target.y = enemys[i].y + y
			target.p = rate
			target.id = mid
		end
	end
	--���Ŷݼ�
	if GetWarMap(x, y, 6) == 3 then
		target.p = target.p * 1.1
	elseif GetWarMap(x, y, 6) == 2 then
		target.p = target.p * 1.01
	end

	if target.p > 0 and kungfuid == 27 then
		if War_Direct(x, y, target.x, target.y) == WAR.Person[target.id]["�˷���"] then
			target.p = target.p * 1.3
		end
	end

 	return target.p, target.x, target.y
end

function War_FindNextStep1(steparray,step,id,idb)      --������һ�����ƶ�������
	--������ĺ�������   
	local num=0;
	local step1=step+1;

	steparray[step1]={};
	steparray[step1].bushu={};
	steparray[step1].x={};
	steparray[step1].y={};

	local function fujinnum(tx,ty)
		local tnum=0
		local wofang=WAR.Person[id]["�ҷ�"]
		local tv;
		tv=GetWarMap(tx+1,ty,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["�ҷ�"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["�ҷ�"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx-1,ty,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["�ҷ�"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["�ҷ�"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx,ty+1,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["�ҷ�"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["�ҷ�"]~=wofang then
				tnum=tnum+1
			end
		end
		tv=GetWarMap(tx,ty-1,2);
		if idb==nil then
			if tv~=-1 then
				if WAR.Person[tv]["�ҷ�"]~=wofang then
					return -1
				end
			end
		elseif tv==idb then
			return -1
		end
		if tv~=-1 then
			if WAR.Person[tv]["�ҷ�"]~=wofang then
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
	    if x+1<CC.WarWidth-1 then                        --��ǰ���������ڸ�
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

	    if x-1>0 then                        --��ǰ���������ڸ�
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

	    if y+1<CC.WarHeight-1 then                        --��ǰ���������ڸ�
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

	    if y-1>0 then                        --��ǰ���������ڸ�
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
--������Ʒ
function War_PersonTrainDrug(pid)
	local p = JY.Person[pid]
	local thingid = p["������Ʒ"]
	if thingid < 0 then
		return
	end
	if JY.Thing[thingid]["������Ʒ�辭��"] <= 0 then
		return
	end
	local needpoint = (7 - math.modf(p["����"] / 15)) * JY.Thing[thingid]["������Ʒ�辭��"]
	if p["��Ʒ��������"] < needpoint then
		return
	end

	local haveMaterial = 0
	local MaterialNum = -1
	for i = 1, CC.MyThingNum do
		if JY.Base["��Ʒ" .. i] == JY.Thing[thingid]["�����"] then
			haveMaterial = 1
			MaterialNum = JY.Base["��Ʒ����" .. i]
		end
	end

	--�����㹻
	if haveMaterial == 1 then
		local enough = {}
		local canMake = 0
		for i = 1, 5 do
			if JY.Thing[thingid]["������Ʒ" .. i] >= 0 and JY.Thing[thingid]["��Ҫ��Ʒ����" .. i] <= MaterialNum then
				canMake = 1
				enough[i] = 1
			else
				enough[i] = 0
			end
		end
		--��������
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

			local newThingID = JY.Thing[thingid]["������Ʒ" .. makeID]
			DrawStrBoxWaitKey(string.format("%s ����� %s", p["����"], JY.Thing[newThingID]["����"]), C_WHITE, CC.DefaultFont)
			if instruct_18(newThingID) == true then
				instruct_32(newThingID, 1)
			else
				instruct_32(newThingID, 1)
			end
			instruct_32(JY.Thing[thingid]["�����"], -JY.Thing[thingid]["��Ҫ��Ʒ����" .. makeID])
			p["��Ʒ��������"] = 0
		end
	end
end
--��������ж�����
--pid ʹ���ˣ�
--enemyid  �ж���
function War_PoisonHurt(pid, enemyid)
	local vv = math.modf((JY.Person[pid]["�ö�����"] - JY.Person[enemyid]["��������"]) / 4)
	--����ţ�ڳ����ѹ��ö�+50
	if JY.Status == GAME_WMAP then
		for i,v in pairs(CC.AddPoi) do
			if match_ID(pid, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["������"], v[2]) and WAR.Person[wid]["����"] == false then
						vv = vv + v[3] / 4
					end
				end
			end
		end
	end
	vv = vv - JY.Person[enemyid]["����"] / 200
	for i = 1, 10 do
		if JY.Person[enemyid]["�书" .. i] == 108 then
			vv = 0
		end
	end
	vv = math.modf(vv)
	if vv < 0 then
		vv = 0
	end
	return AddPersonAttrib(enemyid, "�ж��̶�", vv)
end

--���ﰴ�Ṧ��������
function WarPersonSort(flag)
	for i = 0, WAR.PersonNum - 1 do
		local id = WAR.Person[i]["������"]
		local p = JY.Person[id]
		WAR.Person[i]["�Ṧ"] = JY.Person[id]["�Ṧ"]
		--�з���ս���Ṧ����������͵ȼ��ӳ�
		--[[���¼ӳ�
		for ii,v in pairs(CC.AddSpd) do
			if match_ID(id, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["������"], v[2]) and WAR.Person[wid]["����"] == false then
						WAR.Person[i]["�Ṧ"] = WAR.Person[i]["�Ṧ"] + v[3]
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
			if WAR.Person[maxid]["�Ṧ"] < WAR.Person[j]["�Ṧ"] then
				maxid = j;
			end
		end
		WAR.Person[maxid], WAR.Person[i] = WAR.Person[i], WAR.Person[maxid]
	end
end

--��ʾ�ǹ���ʱ�ĵ���
function War_Show_Count(id, str)
	if JY.Restart == 1 then
		return
	end

	local pid = WAR.Person[id]["������"];
	local x = WAR.Person[id]["����X"];
	local y = WAR.Person[id]["����Y"];

	local hp = WAR.Person[id]["��������"];
	local mp = WAR.Person[id]["��������"];
	local tl = WAR.Person[id]["��������"];
	local ed = WAR.Person[id]["�ж�����"];
	local dd = WAR.Person[id]["�ⶾ����"];
	local ns = WAR.Person[id]["���˵���"];

	local show = {x, y, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};		--x, y, ����, ����, ����, ��Ѩ, ��Ѫ, �ж�, �ⶾ, ���ˣ����⣬����

	if hp ~= nil and hp ~= 0 then		--��ʾ����
		if hp > 0 then
			show[3] = "����+"..hp;
		else
			show[3] = "����"..hp;
		end
	end

	if mp ~= nil and mp ~= 0 then		--��ʾ����
		if mp > 0 then
			show[5] = "����+"..mp;
		else
			show[5] = "����"..mp;
		end
	end

	if tl ~= nil and tl ~= 0 then		--��ʾ����
		if tl > 0 then
			show[6] = "����+"..tl;
		else
			show[6] = "����"..tl;
		end
	end

    if WAR.FXXS[WAR.Person[id]["������"]] ~= nil and WAR.FXXS[WAR.Person[id]["������"]] == 1 then			--��ʾ�Ƿ��Ѩ
       	show[7] = "��Ѩ "..WAR.FXDS[WAR.Person[id]["������"]];
       	WAR.FXXS[WAR.Person[id]["������"]] = 0
    end

    if WAR.LXXS[WAR.Person[id]["������"]] ~=nil and WAR.LXXS[WAR.Person[id]["������"]] == 1 then		--��ʾ�Ƿ���Ѫ
      	show[8] = "��Ѫ "..WAR.LXZT[WAR.Person[id]["������"]];
        WAR.LXXS[WAR.Person[id]["������"]] = 0
    end

	if ed ~= nil and ed ~= 0 then		--��ʾ�ж�
		show[9] = "�ж�+"..ed;
	end

	if dd ~= nil and dd ~= 0 then		--��ʾ�ⶾ
		show[4] = "�ж�-"..dd;
	end

	if ns ~= nil and ns ~= 0 then		--��ʾ����
		if ns > 0 then
			show[10] = "���ˡ�"..ns;
		else
			show[10] = "���ˡ�"..-ns;
		end
	end

	if WAR.BFXS[WAR.Person[id]["������"]] == 1 then		--��ʾ�Ƿ񱻱���
		show[11] = "���� "..JY.Person[WAR.Person[id]["������"]]["����̶�"];
		WAR.BFXS[WAR.Person[id]["������"]] = 0
	end

	if WAR.ZSXS[WAR.Person[id]["������"]] == 1 then		--��ʾ�Ƿ�����
		show[12] = "���� "..JY.Person[WAR.Person[id]["������"]]["���ճ̶�"];
		WAR.ZSXS[WAR.Person[id]["������"]] = 0
	end

	--��¼�ĸ�λ�����е���
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

	local ll = string.len(show[showValue[1]]);	--����

	local w = ll * CC.DefaultFont / 2 + 1
	local clip = {x1 = CC.ScreenW / 2 - w/2 - CC.XScale/2, y1 = CC.YScale + CC.ScreenH / 2 - hb, x2 = CC.XScale + CC.ScreenW / 2 + w, y2 = CC.YScale + CC.ScreenH / 2 + CC.DefaultFont + 1}
	local area = (clip.x2 - clip.x1) * (clip.y2 - clip.y1) + CC.DefaultFont*4		--�滭�ķ�Χ
	local surid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)		--�滭���

	for i = 5, 18 do
		if JY.Restart == 1 then
			break
		end
		local tstart = lib.GetTime()
		local y_off = i * 2

		lib.SetClip(0, 0, CC.ScreenW, CC.ScreenH)
		lib.LoadSur(surid, 0, 0)
		--��ʾ����
		if str ~= nil then
			DrawString(clip.x1 - #str*CC.Fontsmall/5 + 30, clip.y1 - y_off - CC.DefaultFont*4, str, C_WHITE, CC.Fontsmall);
		end
		for j=1, showNum do
			local c = showValue[j] - 1;
			if showValue[j] == 3 and (string.sub(show[3],1,1) == "-" or string.sub(show[3],2,2) == "-") then		--������������ʾΪ��ɫ
				c = 1;
			end
			DrawString(clip.x1, clip.y1 - y_off - (showNum-j+1)*CC.DefaultFont, show[showValue[j]], WAR.L_EffectColor[c], CC.DefaultFont);
		end

		ShowScreen(1)
		lib.SetClip(0, 0, 0, 0)		--���
		local tend = lib.GetTime()
		if tend - tstart < CC.BattleDelay then
			lib.Delay(CC.BattleDelay - (tend - tstart))
		end
	end

	lib.SetClip(0, 0, 0, 0)		--���
	WAR.Person[id]["��������"] = nil;
	WAR.Person[id]["��������"] = nil;
	WAR.Person[id]["��������"] = nil;
	WAR.Person[id]["�ж�����"] = nil;
	WAR.Person[id]["�ⶾ����"] = nil;
	WAR.Person[id]["���˵���"] = nil;

	lib.FreeSur(surid)
end

--����ҽ����
--id1 ҽ��id2, ����id2�������ӵ���
function ExecDoctor(id1, id2)
	if JY.Person[id1]["����"] < 50 then
		return 0
	end
	local add = JY.Person[id1]["ҽ������"]
	local value = JY.Person[id2]["���˳̶�"]
	if add + 20 < value then
		return 0
	end

	-- ƽһָ��ҽ������ɱ�����й�
	if match_ID(id1, 28) and JY.Status == GAME_WMAP then
		add = math.modf(JY.Person[id1]["ҽ������"] * (1 + WAR.PYZ / 10))
	end

	--ս��״̬��ҽ��
	--����ڳ�������ҽ��+120
	--���ѹ��ڳ�����ţҽ��+50
	if JY.Status == GAME_WMAP then
		for i,v in pairs(CC.AddDoc) do
			if match_ID(id1, v[1]) then
				for wid = 0, WAR.PersonNum - 1 do
					if match_ID(WAR.Person[wid]["������"], v[2]) and WAR.Person[wid]["����"] == false then
						add = add + v[3]
					end
				end
			end
		end
	end

	add = add - (add) * value / 200
	add = math.modf(add) + Rnd(5)

	local n = AddPersonAttrib(id2, "���˳̶�", -math.modf((add) / 10))
	--�����壺ҽ��ʱ��ʾ���˼���
	if JY.Status == GAME_WMAP then
		local p = -1;
		for wid = 0, WAR.PersonNum - 1 do
			if WAR.Person[wid]["������"] == id2 and WAR.Person[wid]["����"] == false then
				p = wid;
				break;
			end
		end
		WAR.Person[p]["���˵���"] = n;
	end
	return AddPersonAttrib(id2, "����", add)
end

--�޾Ʋ����������书�˺���WAR.CurIDΪ������
function War_WugongHurtLife(enemyid, wugong, level, ang, x, y)

	local pid = WAR.Person[WAR.CurID]["������"]
	local eid = WAR.Person[enemyid]["������"]
	--����
	local dng = 0
	local WGLX = JY.Wugong[wugong]["�书����"]

	--�޾Ʋ�������¼����Ѫ��
	WAR.Person[enemyid]["Life_Before_Hit"] = JY.Person[eid]["����"]

	--�ɷ罣������Ч��
    if wugong == 27 and IsBackstab(WAR.CurID, enemyid) then
		JY.Person[eid]["���˳̶�"] = JY.Person[eid]["���˳̶�"] + 10
		WAR.Person[enemyid]["��Ч����"] = 93
		Set_Eff_Text(enemyid, "��Ч����2", "��Ǵ�����")
    end

	local hurt = War_CalculateDamage(pid, eid, wugong)
	JY.Person[pid]["�����ڹ�"] = wugong
	if WAR.DZXY ~= 1 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[enemyid]["�ҷ�"] and JY.Person[eid]["�����ڹ�"] > 0 then
		WAR.Person[enemyid]["�����书"] = JY.Person[eid]["�����ڹ�"]
	end
	--���˴��Լ���
	--[[if WAR.Person[WAR.CurID]["�ҷ�"] == WAR.Person[enemyid]["�ҷ�"] then
		--�ҷ�
		if WAR.Person[WAR.CurID]["�ҷ�"] then
			--ˮ�����˼�Ѫ
			if match_ID(pid, 589) then
				hurt = -(math.modf(hurt) + Rnd(3))
			--����������30%
			else
				hurt = math.modf(hurt * 0.3) + Rnd(3)
			end
		--NPC������=20%
		else
			--�������100%
			if WAR.NZQK == 3 then
			
			--������תǬ����NPC���������50%
			elseif WAR.NZQK == 0 then
				hurt = math.modf(hurt * 0.2) + Rnd(3)
			else
				hurt = math.modf(hurt * 0.5) + Rnd(3)
			end
		end
	end]]

	--�޾Ʋ������˺��Ľ��㵽��Ϊֹ���۳���������Ѫ��
	JY.Person[eid]["����"] = JY.Person[eid]["����"] - hurt
	--��������
	if JY.Person[eid]["����"] < 0 then
		JY.Person[eid]["����"] = 0
		WAR.Person[WAR.CurID]["����"] = WAR.Person[WAR.CurID]["����"] + JY.Person[eid]["�ȼ�"] * 5
		WAR.Person[enemyid]["�����书"] = -1		--����������򲻻ᴥ������
		if WAR.SZSD == eid then						--ȡ����ս���
			WAR.SZSD = -1
		end
	end
	--[[���˲���ʾ����
	if DWPD() == false then
		WAR.Person[enemyid]["��Ч����"] = -1
		WAR.Person[enemyid]["��Ч����0"] = nil
		WAR.Person[enemyid]["��Ч����1"] = nil
		WAR.Person[enemyid]["��Ч����2"] = nil
		WAR.Person[enemyid]["��Ч����3"] = nil
		WAR.Person[enemyid]["��Ч����4"] = nil
	end]]

	return limitX(hurt, 0, hurt);
end

-- ����ս����ͼ
-- flag=0  ���ƻ���ս����ͼ
--     =1  ��ʾ���ƶ���·����(v1,v2)��ǰ�ƶ����꣬��ɫ����(ѩ��ս��)
--     =2  ��ʾ���ƶ���·����(v1,v2)��ǰ�ƶ����꣬��ɫ����
--     =3  ���е������ð�ɫ������ʾ
--     =4  ս����������  v1 ս������pic, v2��ͼ�����ļ����ļ�id
--                       v3 �书Ч��pic  -1��ʾû���书Ч��
function WarDrawMap(flag, v1, v2, v3, v4, v5, ex, ey)
	local x = WAR.Person[WAR.CurID]["����X"]
	local y = WAR.Person[WAR.CurID]["����Y"]
	if not v4 then
		v4 = JY.SubScene
	end
	if not v5 then
		v5 = -1;
	end

	if flag == 0 then
		lib.DrawWarMap(0, x, y, 0, 0, -1, v4)
	elseif flag == 1 then
		--��쳾ӣ�ѩɽ���м��ջ�������ǣ������ǣ���ɽ����
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
			HP_Display_When_Idle()	--��̬��Ѫ
		end
	end
end

--�з�ս������
function WarSelectEnemy()
	--�з������ر����
	if PNLBD[WAR.ZDDH] ~= nil then
		PNLBD[WAR.ZDDH]()
	end

	for i = 1, 20 do
		if WAR.Data["����" .. i] > 0 then
			--�������������´ﺣ
			if WAR.ZDDH == 92 and GetS(87,31,33,5) == 1 then
				for i=2,5 do
					WAR.Data["����" .. i] = -1;
				end
			end

			--�޾Ʋ��������۽�����
			if WAR.ZDDH == 266 then
				WAR.Data["����1"] = GetS(85, 40, 38, 4)
			end

			WAR.Person[WAR.PersonNum]["������"] = WAR.Data["����" .. i]
			WAR.Person[WAR.PersonNum]["�ҷ�"] = false
			WAR.Person[WAR.PersonNum]["����X"] = WAR.Data["�з�X" .. i]
			WAR.Person[WAR.PersonNum]["����Y"] = WAR.Data["�з�Y" .. i]
			WAR.Person[WAR.PersonNum]["����"] = false
			WAR.Person[WAR.PersonNum]["�˷���"] = 1
			--�޾Ʋ���������ս����ʼ����
			--ս����
			if WAR.ZDDH == 259 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 2
			end
			--˫������ֹ
			if WAR.ZDDH == 273 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--���������
			if WAR.ZDDH == 275 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--ս����
			if WAR.ZDDH == 75 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--�ɸ�
			if WAR.ZDDH == 278 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--����������
			if WAR.ZDDH == 279 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--��������
			if WAR.ZDDH == 293 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--��ڤ����
			if WAR.ZDDH == 295 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 3
			end
			--��������Ⱥ
			if WAR.ZDDH == 298 then
				WAR.Person[WAR.PersonNum]["�˷���"] = 2
			end
			WAR.PersonNum = WAR.PersonNum + 1
		end
	end
end

--����ս��������ͼ
function WarCalPersonPic(id)
	local n = 5106
	n = n + JY.Person[WAR.Person[id]["������"]]["ͷ�����"] * 8 + WAR.Person[id]["�˷���"] * 2
	return n
end

--�����׼��������������ͼ
function WarCalPersonPic2(id, gender)
	local n = 5058
	if gender == 1 then
		n = 5010
	end
	n = n + WAR.Person[id]["�˷���"] * 12
	return n
end

--ս���Ƿ����
function War_isEnd()
	for i = 0, WAR.PersonNum - 1 do
		if JY.Person[WAR.Person[i]["������"]]["����"] <= 0 then
			WAR.Person[i]["����"] = true
		end
	end
	WarSetPerson()
	Cls()
	ShowScreen()
	local myNum = 0
	local EmenyNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			if WAR.Person[i]["�ҷ�"] == true then
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

--�޾Ʋ�����ս���Ƿ����2
function War_isEnd2()
	local myNum = 0
	local EmenyNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			if WAR.Person[i]["�ҷ�"] == true then
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

--����ս��ȫ�ֱ���
function WarSetGlobal()
	WAR = {}
	WAR.Data = {}
	WAR.Person = {}
	WAR.MCRS = 0 --�޾Ʋ�����ÿ��ս��ѡ������
	for i = 0, 30 do
		WAR.Person[i] = {}
		WAR.Person[i]["������"] = -1
		WAR.Person[i]["�ҷ�"] = true
		WAR.Person[i]["����X"] = -1
		WAR.Person[i]["����Y"] = -1
		WAR.Person[i]["����"] = true
		WAR.Person[i]["�˷���"] = -1
		WAR.Person[i]["��ͼ"] = -1
		WAR.Person[i]["��ͼ����"] = 0
		WAR.Person[i]["�Ṧ"] = 0
		WAR.Person[i]["�ƶ�����"] = 0
		WAR.Person[i]["����"] = 0
		WAR.Person[i]["�Զ�ѡ�����"] = -1
		WAR.Person[i].Move = {}
		WAR.Person[i].Action = {}
		WAR.Person[i].Time = 0
		WAR.Person[i].TimeAdd = 0
		WAR.Person[i].SpdAdd = 0
		WAR.Person[i].Point = 0
		WAR.Person[i]["��Ч����"] = -1
		WAR.Person[i]["�����书"] = -1
		WAR.Person[i]["��Ч����0"] = nil
		WAR.Person[i]["��Ч����1"] = nil
		WAR.Person[i]["��Ч����2"] = nil
		WAR.Person[i]["��Ч����3"] = nil
		WAR.Person[i]["��Ч����4"] = nil	--�޾Ʋ������ӵ����� 8-11
	end
	WAR.PersonNum = 0
	WAR.AutoFight = 0
	WAR.CurID = -1
	WAR.SXTJ = 0		--ʱ��
	WAR.SSX_Counter = 0	--��ʱ�������
	WAR.WSX_Counter = 0	--��ʱ�������
	WAR.LSX_Counter = 0	--��ʱ�������
	WAR.JSX_Counter = 0	--��ʱ�������
	WAR.ZSHY = {}		--ת˲���ռ�����
	WAR.WGWL = 0		--��¼�书10���Ĺ�����
	WAR.ZYHB = 0		--���һ�����1���������ҵĻغϣ�2�����ҵĶ���غ�
	WAR.ZYHBP = -1		--��¼�������ҵ��˵ı��
	WAR.PREVIEW = -1	--��¼����Ԥ�����˵ı��
	WAR.ZHB = 0			--�ܲ�ͨ��׷�������ж�
	WAR.AQBS = 0		--��������
	WAR.BJ = 0			--����
	WAR.XK = 0			--����֮ŭХ
	WAR.XK2 = nil
	WAR.TD = -1			--͵��
	WAR.TDnum = 0		--͵������
	WAR.HTSS = 0		--ҽ������
	WAR.ZSF = 0			--����������Ȼ
	WAR.XZZ = 0			--������ӻ�
	WAR.KFKJ = 0		--�ⲻƽ���콣
	WAR.WCY = {}		--һ�Ƹ���
	WAR.CYZX = {} 		--����������
	WAR.BDQS = 0		--�������������״̬����
	WAR.QCF = 0			--�ݳ�������
	WAR.HTS = 0			--�������嶾���2-5������
	WAR.FS = 0			--�İ���֮ս���Ƿ�������
	WAR.ZBT = 1			--�ܲ�ͨ��ÿ�ж�һ�Σ�����ʱ�˺�һ+10%
	WAR.HQT = 0			--����ͩ ɱ����
	WAR.CY = 0			--��Ӣ ɱ����
	WAR.HDWZ = 0		--��������϶�
	WAR.ZJZ = 0			--����棬����õ�ʳ��
	WAR.YJ = 0			--�ֻ�͵Ǯ
	WAR.XMH = 0			--ѦĽ�� ����һ����
	WAR.PYZ = 0			--ƽһָɱ��
	WAR.DJGZ = 0		--��������
	WAR.WS = 0			--����
	WAR.ACT = 1			--��������
	WAR.ZDDH = -1		--ս������
	WAR.NO1 = -1		--�ɰ��۽���һ��
	WAR.TJAY = 0		--̫������
	WAR.LYSH = 0 		--�����ػ�
	WAR.TKXJ = 0		--̫��ж��
	WAR.DZXY = 0		--��ת����
	WAR.fthurt = 0		--Ǭ���������˺�
	WAR.LXZQ = 0		--ȭ������
	WAR.LXYZ = 0		--ָ������
	WAR.JSYX = 0		--�������
	WAR.ASKD = 0		--��������
	WAR.YZHYZ = 0		--������������ŭ������
	WAR.GCTJ = 0		--���Ŵ���
	WAR.JSTG = 0		--�����
	WAR.YTML = 0 		--��������
	WAR.NGXS = 0		--�ڹ�������ϵ��
	WAR.TXZZ = 0		--̫��֮��
	WAR.MMGJ = 0		--äĿ����
	WAR.TFBW = 0		--�����λ�����ּ�¼
	WAR.TLDWX = 0		--���޵��������ּ�¼
	WAR.JSAY = 0		--���߰���
	WAR.TLDW = {}		--���޵���
	WAR.OYFXL = 0 		--ŷ������ݸ�����������˺�
	WAR.XDLeech = 0		--Ѫ����Ѫ��
	WAR.WYXLeech = 0	--ΤһЦ��Ѫ��
	WAR.TMGLeech = 0	--��ħ����Ѫ��
	WAR.XHSJ = 0		--Ѫ�������Ѫ��
	WAR.WDRX = 0		--��Զ��ʹ��̫��ȭ��̫�����������Զ��������״̬
	WAR.KMZWD = 0 		--�ܲ�ͨ����֮���
	WAR.ARJY = 0		--��Ȼ����
	WAR.LFHX = 0 		--�ֳ�Ӣ�����ѩ
	WAR.YYBJ = 0 		--���������಻��
	WAR.YNXJ = 0		--��Ů�ľ���ز�ÿձ�
	WAR.HXZYJ = 0		--����֮һ��
	WAR.QQSH1 = 0		--�����黭֮������
	WAR.QQSH2 = 0		--�����黭֮��ʵ���
	WAR.QQSH3 = 0		--�����黭֮����������
	WAR.YZQS = 0		--һ������
	WAR.TYJQ = 0		--������Ԫ����
	WAR.OYK = 0 		--ŷ��������ȭ
	WAR.JQBYH = 0		--�������������̺�
	WAR.CMDF = 0		--���鵶��
	WAR.NZQK = 0		--��תǬ��
	WAR.TXXS = {} 		--��Ч������ʾ
	WAR.BXCF = 0 		--Ԭ��־��Ѫ����
	WAR.FLHS1 = 0		--�伲���
	WAR.FLHS2 = 0		--��������
	WAR.FLHS4 = 0		--������ɽ
	WAR.FLHS5 = 0		--��֪����
	WAR.FLHS6 = 0		--��������
	WAR.NGJL = 0		--��ǰ�����ڹ����
	WAR.NGHT = 0		--��ǰ�����ڹ����
	WAR.CQSX = 0		--��ȴ����
	WAR.BMXH = 0		--��������
	WAR.ZYYD = 0		--��¼���ҵ�ʥ���ƶ�����
	WAR.LMSJwav = 0		--�����񽣵���Ч
	WAR.JGZ_DMZ = 0		--��Ħ��
	WAR.LHQ_BNZ = 0		--������
	WAR.WD_CLSZ = 0		--��������
	WAR.ShowHead = 0	--��ʾ���½�ͷ����Ϣ
	WAR.Effect = 0		--���ι�����Ч����2���˺���3��ɱ�ڣ�4��ҽ�ƣ�5���϶���6���ⶾ
	WAR.Delay = 0
	WAR.LifeNum = 0
	WAR.EffectXY = nil
	WAR.EffectXYNum = 0
	WAR.tmp = {}		--200����󡹦������1000��ŷ���������߻�2000��̫��ȭ������3000�����ո��5000��ͷ����
	WAR.Actup = {}		--������¼
	WAR.Defup = {}		--������¼
	WAR.Wait = {}		--�ȴ���¼
	WAR.HMGXL = {}		--�����������300����
	WAR.Weakspot = {}	--��������
	WAR.KHBX = 0		--������Ŀ
	WAR.KHCM = {}		--����Ŀ���˼�¼
	WAR.LQZ = {}		--ŭ��ֵ
	WAR.FXDS = {}		--��Ѩ����
	WAR.FXXS = {}		--��Ѩ��ʾ
	WAR.LXZT = {}		--��Ѫ����
	WAR.LXXS = {}		--��Ѫ��ʾ
	WAR.BFXS = {}		--������ʾ
	WAR.ZSXS = {}		--������ʾ
	WAR.SZJPYX = {}		--�Ѿ��ṩ��ʵս���˼�¼���������ģ�
	WAR.TZ_MRF = 0		--Ľ�ݸ�ָ��
	WAR.TZ_DY = 0		--����ָ��
	WAR.TZ_XZ = 0		--����ָ��
	WAR.TZ_XZ_SSH = {}	--�������������˼�¼
	WAR.BFX = 0			--�ط�Ѩ
	WAR.BLX = 0			--����Ѫ
	WAR.BBF = 0 		--�ر���
	WAR.BZS = 0			--������
	WAR.TXZQ = {}		--̫��֮��
	WAR.GSWS = 0 		--������˫
	WAR.JQSDXS = {} 	--�޾Ʋ����������ٶ���ʾ
	WAR.TWLJ = 0 		--��������
	WAR.hit_DGQB = 0	--�޾Ʋ�����������ܷ�������Ч��ʾ
	WAR.WXFS = nil		--����ˮ�������ı�ż�¼
	WAR.JJPZ = {} 		--�޾Ʋ������Ž�����
	WAR.TKJQ = {}		--̫��ж�����ټ���
	WAR.JJZC = 0		--�Ž��洫��4������������Ч
	WAR.JJDJ = 0 		--�Ž�����ʽ����
	WAR.Dodge = 0		--�ж��Ƿ�����
	WAR.TJZX = {}		--̫��֮�μ�¼
	WAR.TJZX_LJ = 0		--̫��֮������
	WAR.CXLC = 0		--���Ƴ�������
	WAR.CXLC_Count = 0	--���Ƴ������Ǽ���
	WAR.FQY = 0			--����������ʤ����
	WAR.WZSYZ = {}		--������ʤ���л��е���
	WAR.ZXXS = {}		--��ϼ����
	WAR.GMYS = 0		--��ң����Ӽ���
	WAR.GMZS = {}		--�����д��е��˼�¼
	WAR.LPZ = 0			--��ƽ֮����


	WAR.JYFX = {}		--����7ʱ������Ѩ
	WAR.L_TLD = 0;		--װ����������Ч��1��Ѫ
	WAR.PJTX = 0 		--�������������������ƾ�����
	WAR.QYBY = {}		--�ֳ�Ӣ���Ʊ��£�ÿ50ʱ��ɴ���һ�Σ������˺�10ʱ��
	WAR.XZ_YB = {}		--С��Ӱ����¼
	WAR.LSQ = {}		--������ȭ���е��˼�¼

	WAR.HP_Bonus_Count = {}	--��¼Ѫ�������ı��

	WAR.L_EffectColor = {}					--�쳣״̬����ɫ��ʾ
	WAR.L_EffectColor[1] = M_Silver;		--��ʾ��������
	WAR.L_EffectColor[2] = M_Pink;			--��ʾ��������
	WAR.L_EffectColor[3] = M_LightBlue;		--��ʾ�ⶾ
	WAR.L_EffectColor[4] = M_DeepSkyBlue;	--��ʾ�������ٺ�����
	WAR.L_EffectColor[5] = M_PaleGreen;		--��ʾ�������ٺ�����
	WAR.L_EffectColor[6] = C_GOLD;			--��ʾ��Ѩ
	WAR.L_EffectColor[7] = M_Red;			--��ʾ��Ѫ
	WAR.L_EffectColor[8] = M_DarkGreen;		--��ʾ�ж�
	WAR.L_EffectColor[9] = PinkRed;			--��ʾ���˼��ٺ�����
	WAR.L_EffectColor[10] = LightSkyBlue;	--��ʾ����
	WAR.L_EffectColor[11] = C_ORANGE;		--��ʾ����

	WAR.L_WNGZL = {};		--���ѹ�ָ������ж���Ѫ
	WAR.L_HQNZL = {};		--����ţָ�������Ѫ������

	WAR.L_QKDNY = {};		--�趨���������ʱ��Ǭ��ֻ�ܱ���һ��

	WAR.L_NOT_MOVE = {};	--��¼�����ƶ�����
	WAR.XDLZ = {};			--��¼��Ѫ������ɱ������
	WAR.ZZRZY = 0			--�������������ҵľ���
	WAR.XTTX = 0			--�����Ϣ

	WAR.ShowHP = 1			--Ѫ����ʾ

	WAR.FF = 0				--���Ǿ��Ѻ����㿪��ǰ���β����˺�

	WAR.ZQHT = 0 			--�Ƿ񴥷���������
	WAR.TSSB = {}			--����̩ɽ��ʹ�ú�20ʱ��������
	WAR.JDYJ = {}			--��������������������
	WAR.WMYH = {}			--����ҵ��״̬������ʹ�õ�����һ�������

	WAR.JHLY = {}			--�޾Ʋ������ٻ���ԭ������+ȼľ+���浶
	WAR.LRHF = {}			--�޾Ʋ��������к��棬����+����+����

	WAR.SLSX = {}			--���֣�ʮ��ʮ��
	WAR.HMZT = {}			--����״̬

	WAR.JYZT = {}			--���ϣ���ҩ״̬
	WAR.MZSH = 0			--��������ɳ����ÿɱһ����+200��������

	WAR.SZSD = -1			--����ս������Ŀ��

	WAR.CSZT = {}			--��˯״̬

	WAR.PJZT = {}			--�ƾ�״̬
	WAR.PJJL = {}			--���ƾ�ǰ���ڹ���¼

	WAR.YSJF = {}			--��ʯ���

	WAR.HLZT = {}			--����״̬

	WAR.QYZT = {}			--����״̬

	WAR.XRZT = {}			--����״̬

	WAR.QGZT = {}			--���״̬

	WAR.BXZS = 0				--��а��ʽ
	WAR.BXLQ = {}				--��а��ȴ��¼
	WAR.BXCD = {0,1,0,1,2,3}	--��а��ȴʱ��

	WAR.KHSZ = 0			--��������

	WAR.JSBM = {}			--������

	CleanWarMap(7, 0)
end


--��ʾ�����ս����Ϣ������ͷ��������������
function WarShowHead(id)
	if not id then
		id = WAR.CurID
	end
	if id < 0 then
		return
	end
	local pid = WAR.Person[id]["������"]
	local p = JY.Person[pid]
	local h = CC.FontSMALL
	local width = CC.FontSMALL*11 - 6
	local height = (CC.FontSMALL+CC.RowPixel)*9 - 12
	local x1, y1 = nil, nil
	local i = 1
	local size = CC.FontSmall3
	if p["�����ڹ�"] > 0 then
		height = height + CC.FontSMALL + 2
	end
    if p["�����Ṧ"] > 0 then
		height = height + CC.FontSMALL + 2
	end
	if WAR.Person[id]["�ҷ�"] == true then
		x1 = CC.ScreenW - width - 6
		y1 = CC.ScreenH - height - CC.ScreenH/6 -6
		DrawBox(x1, y1, x1 + width, y1 + height + CC.ScreenH/6, C_GOLD)
	else
		x1 = 10
		y1 = 10
		DrawBox(x1, y1, x1 + width, y1 + height + CC.ScreenH/6, C_GOLD)
	end

	---------------------------------------------------------״̬��ʾ---------------------------------------------------------

	local zt_num = 0

	--����������ʾ
	if WAR.tmp[2000 + pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 1 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1, "�����ո���", C_WHITE, size)
		else
			lib.LoadPNG(98, 1 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3, "�����ո���", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--̫��֮����ʾ
	if Curr_NG(pid, 171) then
		local tjzx = WAR.TJZX[pid] or 0
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 2 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "̫��֮��:"..tjzx, C_WHITE, size)
		else
			lib.LoadPNG(98, 2 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "̫��֮��:"..tjzx, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--���ٲ���ʾ
	if pid == 0 and JY.Person[615]["�۽�����"] == 1 then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 3 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "���ٲ�����", C_WHITE, size)
		else
			lib.LoadPNG(98, 3 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "���ٲ�����", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--����ɺ�������齣��ʾ
	if match_ID(pid, 79) then
		local JF = 0
		for i = 1, CC.Kungfunum do
			if JY.Wugong[JY.Person[pid]["�书" .. i]]["�书����"] == 3 then
				JF = JF + 1
			end
		end
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 4 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "�����齣:"..JF, C_WHITE, size)
		else
			lib.LoadPNG(98, 4 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "�����齣:"..JF, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--����������ʾ
	if JiandanQX(pid) then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 5 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��������", C_WHITE, size)
		else
			lib.LoadPNG(98, 5 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��������", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--����ҵ����ʾ	
	if WAR.WMYH[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 6 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����ҵ��:"..WAR.WMYH[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 6 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����ҵ��:"..WAR.WMYH[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�����޷���ʾ
	if TianYiWF(pid) then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 7 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "�����޷�", C_WHITE, size)
		else
			lib.LoadPNG(98, 7 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "�����޷�", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ������ٻ���ԭ������+ȼľ+���浶�������ȼЧ��
	if WAR.JHLY[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 8 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��ȼ״̬:"..WAR.JHLY[pid].."ʱ��", C_WHITE, size)
		else
			lib.LoadPNG(98, 8 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��ȼ״̬:"..WAR.JHLY[pid].."ʱ��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ��������к��棬����+����+���飬��ɶ���Ч��
	if WAR.LRHF[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 9 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����״̬:"..WAR.LRHF[pid].."ʱ��", C_WHITE, size)
		else
			lib.LoadPNG(98, 9 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����״̬:"..WAR.LRHF[pid].."ʱ��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ���������ս������Ŀ��
	if pid == WAR.SZSD then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 10 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��սĿ��", C_WHITE, size)
		else
			lib.LoadPNG(98, 10 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��սĿ��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ��������� ʮ��ʮ��״̬
	if WAR.SLSX[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 11 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "ʮ��ʮ��", C_WHITE, size)
		else
			lib.LoadPNG(98, 11 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "ʮ��ʮ��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ���������״̬
	if WAR.HMZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 12 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����״̬", C_WHITE, size)
		else
			lib.LoadPNG(98, 12 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����״̬", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�������������ɳ��
	if match_ID(pid, 47) then
		local tjzx = WAR.TJZX[pid] or 0
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 13 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����ɳ��:" .. WAR.MZSH, C_WHITE, size)
		else
			lib.LoadPNG(98, 13 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����ɳ��:" .. WAR.MZSH, C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ��������Ͻ�ҩ״̬
	if WAR.JYZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 14 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��ҩ״̬", C_WHITE, size)
		else
			lib.LoadPNG(98, 14 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��ҩ״̬", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�������˯״̬
	if WAR.CSZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 15 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��˯״̬", C_WHITE, size)
		else
			lib.LoadPNG(98, 15 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��˯״̬", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ������������ʯ���
	if WAR.YSJF[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 16 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "��ʯ���:" .. WAR.YSJF[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 16 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "��ʯ���:" .. WAR.YSJF[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�����ͣ��״̬
	if WAR.PJZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 17 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "ͣ��״̬:" .. WAR.PJZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 17 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "ͣ��״̬:" .. WAR.PJZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ���������״̬
	if WAR.HLZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 18 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����״̬:" .. WAR.HLZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 18 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����״̬:" .. WAR.HLZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ���������״̬
	if WAR.QYZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 19 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����" .. WAR.QYZT[pid].."��", C_WHITE, size)
		else
			lib.LoadPNG(98, 19 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����" .. WAR.QYZT[pid].."��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ���������״̬
	if WAR.XRZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 20 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����״̬:" .. WAR.XRZT[pid], C_WHITE, size)
		else
			lib.LoadPNG(98, 20 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����״̬:" .. WAR.XRZT[pid], C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ��������״̬
	if WAR.QGZT[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 21 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "���ʣ��" .. WAR.QGZT[pid].."��", C_WHITE, size)
		else
			lib.LoadPNG(98, 21 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "���ʣ��" .. WAR.QGZT[pid].."��", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�����äĿ״̬
	if WAR.KHCM[pid] == 2 then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 22 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "äĿ״̬", C_WHITE, size)
		else
			lib.LoadPNG(98, 22 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "äĿ״̬", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�������������
	if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and pid == 27 then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 23 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "����������̬", C_WHITE, size)
		else
			lib.LoadPNG(98, 23 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "����������̬", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ������伲���
	if WAR.FLHS1 == 1 and pid == 0 then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 24 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "�伲���", C_WHITE, size)
		else
			lib.LoadPNG(98, 24 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "�伲���", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end

	--�޾Ʋ�����������
	if WAR.JSBM[pid] ~= nil then
		if WAR.Person[id]["�ҷ�"] == true then
			lib.LoadPNG(98, 25 * 2 , x1 - size*9- CC.RowPixel, CC.ScreenH - size*2 - CC.RowPixel*2 - (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 - size*6- CC.RowPixel, CC.ScreenH - size - CC.RowPixel*3 + 1 - (size*2+CC.RowPixel*2)*zt_num, "������", C_WHITE, size)
		else
			lib.LoadPNG(98, 25 * 2 , x1 + width + CC.RowPixel, CC.RowPixel + 3 + (size*2+CC.RowPixel*2)*zt_num, 1)
			DrawString(x1 + width + size*2 + CC.RowPixel*3, size + 3 + (size*2+CC.RowPixel*2)*zt_num, "������", C_WHITE, size)
		end
		zt_num = zt_num + 1
	end
	--------------------------------------------------------------------------------------------------------------------------

	local headw, headh = lib.GetPNGXY(1, p["ͷ�����"])
	local headx = (width - headw) / 2
	local heady = (CC.ScreenH/5 - headh) / 2
	--ͷ����Ϣ
	local headid = WAR.tmp[5000+id];
	lib.LoadPNG(1, headid*2, x1 + 1 + headx, y1 - 14 + heady, 1)
	x1 = x1 + CC.RowPixel
	y1 = y1 + CC.RowPixel + CC.ScreenH/6 - 12
	local color = nil
	if p["���˳̶�"] < p["�ж��̶�"] then
		if p["�ж��̶�"] == 0 then
			color = RGB(252, 148, 16)
		elseif p["�ж��̶�"] < 50 then
			color = RGB(120, 208, 88)
		else
			color = RGB(56, 136, 36)
		end
	elseif p["���˳̶�"] < 33 then
		color = RGB(236, 200, 40)
	elseif p["���˳̶�"] < 66 then
		color = RGB(244, 128, 32)
	else
		color = RGB(232, 32, 44)
	end
	MyDrawString(x1 -4 , x1 + width -4, y1 + CC.RowPixel + 2, p["����"], color, CC.DefaultFont)
	--���˹�ʱ����ʾ
	if p["�����ڹ�"] > 0 then
		DrawString(x1 + 8, y1 + CC.RowPixel + CC.DefaultFont, "����", MilkWhite, size)
		DrawString(x1 + size*3, y1 + CC.RowPixel+ CC.DefaultFont, JY.Wugong[p["�����ڹ�"]]["����"], TG_Red_Bright, size)
		y1 = y1 + CC.FontSMALL + 2
	end
	--���Ṧʱ����ʾ
	if p["�����Ṧ"] > 0 then
		DrawString(x1 + 8, y1 + CC.RowPixel + CC.DefaultFont, "�Ṧ", MilkWhite, size)
		DrawString(x1 + size*3, y1 + CC.RowPixel+ CC.DefaultFont, JY.Wugong[p["�����Ṧ"]]["����"], M_DeepSkyBlue, size)
		y1 = y1 + CC.FontSMALL + 2
	end
	y1 = y1 + size + CC.RowPixel + 3

	--��ɫ��
	local pcx = x1 + 3 - CC.RowPixel + 2;
	local pcy = y1 + CC.RowPixel +1

	--������
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 274 * 2);

	lib.SetClip(pcx, pcy, pcx + (p["����"]/p["�������ֵ"])*pcw, pcy + pch)
	lib.LoadPNG(1, 274 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	--������
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 273 * 2);
	lib.SetClip(pcx, pcy, pcx + (p["����"]/p["�������ֵ"])*pcw, pcy + pch)
	lib.LoadPNG(1, 273 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	--������
	lib.LoadPNG(1, 275 * 2 , pcx  , pcy, 1)
	local pcw, pch = lib.GetPNGXY(1, 276 * 2);
	lib.SetClip(pcx, pcy, pcx + (p["����"]/100)*pcw, pcy + pch)
	lib.LoadPNG(1, 276 * 2 , pcx  , pcy, 1)
	pcy = pcy + CC.RowPixel + size -2
	lib.SetClip(0,0,0,0)

	local lifexs = "�� "..p["����"]
	local nlxs = "�� "..p["����"]
	local tlxs = "�� "..p["����"]
	local lqzxs = WAR.LQZ[pid] or 0;	--ŭ��
	local zdxs = p["�ж��̶�"]

	local nsxs = p["���˳̶�"];		--����
	local bfxs = p["����̶�"];		--����
	local zsxs = p["���ճ̶�"];		--����
	local fxxs = WAR.FXDS[pid] or 0;		--��Ѩ
	local lxxs = WAR.LXZT[pid] or 0;		--��Ѫ

	DrawString(x1 + 9, y1 + CC.RowPixel + 6, lifexs, M_White, CC.FontSMALL)
	DrawString(x1 + 9, y1 + CC.RowPixel + size + 11, nlxs, M_White, CC.FontSMALL)
	DrawString(x1 + 9, y1 + CC.RowPixel + 2*size + 16, tlxs, M_White, CC.FontSMALL)

	y1 = y1 + 3*(CC.RowPixel + size) + 4

  	local myx1 = 3;
  	local myy1 = 0;
	--ŭ��
	DrawString(x1 + myx1, y1 + myy1, "ŭ��", C_RED, size)
	if lqzxs == 100 then
		lqzxs = "��"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, lqzxs, C_RED, size)
	--����
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "����", M_DeepSkyBlue, size)
	if pid == 0 then
		DrawString(x1 + size*5/2 + myx1, y1 + myy1, WAR.FLHS2, M_DeepSkyBlue, size)
	else
		DrawString(x1 + size*5/2 + myx1, y1 + myy1, "��", M_DeepSkyBlue, size)
	end
	--����
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "����", M_LightBlue, size)
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, bfxs, M_LightBlue, size)
	--����
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "����", C_ORANGE, size)
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, zsxs, C_ORANGE, size)
	--��Ѩ
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "��Ѩ", C_GOLD, size)
	if fxxs == 50 then
		fxxs = "��"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, fxxs, C_GOLD, size)
	--��Ѫ
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "��Ѫ", M_DarkRed, size)
	if lxxs == 100 then
		lxxs = "��"
	end
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, lxxs, M_DarkRed, size)
	--����
	myx1 = 3;
	myy1 = myy1 + size + 2;
	DrawString(x1 + myx1, y1 + myy1, "����", PinkRed, size)
	if nsxs == 100 then
		nsxs = "��"
	end
	DrawString(x1 + myx1 + size*2 + 10, y1 + myy1, nsxs, PinkRed, size)
	--�ж�
	myx1 = myx1 + size * 4;
	DrawString(x1 + myx1, y1 + myy1, "�ж�", LimeGreen, size)
	if zdxs == 100 then
		zdxs = "��"
	end
  	DrawString(x1 + size*5/2 + myx1, y1 + myy1, zdxs, LimeGreen, size)
	if WAR.PREVIEW < 0 then return end

	local pidq = JY.Person[WAR.PREVIEW]["�Ṧ"]
	local eidq = JY.Person[pid]["�Ṧ"]
	local fightnum = 1 + math.modf((pidq - eidq) / 20)
	fightnum = math.max(1, fightnum)

	local fightnum2 = 1 + math.modf((eidq - pidq) / 20)
	fightnum2 = math.max(1, fightnum2)

	local wugong = JY.Person[WAR.PREVIEW]["�۽�����"]
	if WAR.Person[id]["�ҷ�"] == false and wugong > 0 then
		y1 = y1 + 3*(CC.RowPixel + size) +12
		DrawBox(x1-7, y1, x1 + width-7 , y1 + size*6, C_GOLD)
		DrawString(x1+2, y1 + (size + CC.RowPixel) - 18, "����-" .. JY.Wugong[wugong]["����"], C_WHITE, size)
		DrawString(x1+2, y1 + 2 * (size + CC.RowPixel) - 18, "Ԥ���˺���" .. (fightnum * War_PredictDamage(WAR.PREVIEW, pid, wugong)), C_WHITE, size)
		local wugong2 = JY.Person[pid]["�����ڹ�"]
		if wugong2 > 0 then
			local fanjinum = War_PredictDamage(pid, WAR.PREVIEW, wugong2) * fightnum2
			DrawString(x1+2, y1 + 3 * (size + CC.RowPixel) - 18, "����������" .. fanjinum, C_WHITE, size)
			DrawString(x1+2, y1 + 4 * (size + CC.RowPixel) - 18, "ʣ����Ѫ��" .. (JY.Person[WAR.PREVIEW]["����"] - fanjinum), C_WHITE, size)
		end
	end
end

function War_PredictDamage(pid, eid, wugong)
	local def = JY.Person[eid]["������"]
	local true_WL = get_skill_power(pid, wugong)
	local dmg = math.max(true_WL - def, 1)
	return dmg
end

function War_CalculateDamage(pid, eid, wugong)
	local def = JY.Person[eid]["������"]
	local true_WL = get_skill_power(pid, wugong)
	local dmg = math.max(true_WL - def, 1)
	dmg = dmg + JY.Person[eid]["���˳̶�"]
	return dmg
end

--�Զ�ѡ����ʵ��书
function War_AutoSelectWugong()
	local pid = WAR.Person[WAR.CurID]["������"]
	local probability = {}
	local wugongnum = CC.Kungfunum
	for i = 1, CC.Kungfunum do
		local wugongid = JY.Person[pid]["�书" .. i]
		if wugongid > 0 then
			if JY.Wugong[wugongid]["�˺�����"] == 0 then

				--ѡ��ɱ�������书������������������������С��������Է���һ�����书��
				if JY.Wugong[wugongid]["������������"] <= JY.Person[pid]["����"] then
					local level = math.modf(JY.Person[pid]["�书�ȼ�" .. i] / 100) + 1
					probability[i] = get_skill_power(pid, wugongid, level)	--�޾Ʋ����������¹�ʽ
				else
					probability[i] = 0
				end

				--�Ṧ���ɹ���
				if JY.Wugong[wugongid]["�书����"] == 7 then
					probability[i] = 0
				end

				--�ڹ�����
				if JY.Wugong[wugongid]["�书����"] == 6 then

					if inteam(pid) == false and i == 1 then 				--NPC���õ�һ���ڹ�

					elseif pid == 0 and JY.Base["����"] > 0 and i == 1 then --������õ�һ���ڹ�

					elseif wugongid == 105 and (match_ID(pid, 36) or match_ID(pid, 27))then		--��ƽ֮ ���� ʹ�ÿ�����

					elseif wugongid == 102 and match_ID(pid, 38) then		--ʯ���� ʹ��̫����

					elseif wugongid == 106 and match_ID(pid, 9) then		--���޼� ʹ�þ�����

					elseif wugongid == 94 and match_ID(pid, 37) then		--���� ʹ������

					elseif wugongid == 108 and match_ID(pid, 114) then		--ɨ�� ʹ���׽

					elseif wugongid == 93 and match_ID(pid, 66) then		--С�� ʹ��ʥ��

					elseif wugongid == 104 and match_ID(pid, 60) then		--ŷ���� ʹ������

					elseif wugongid == 103 and (match_ID(pid, 39) or match_ID(pid, 40))then		--���͵��� ʹ������

					elseif (pid == 0 and GetS(4, 5, 5, 5) == 5) or match_ID(pid, 48) then		--��� ��̹֮ ʹ���ڹ�

					else
						probability[i] = 0
					end
				end

				--��ת����
				if wugongid == 43 and match_ID(pid, 51) == false then
					probability[i] = 0
				end

				--�Ƿ岻�ô�
				if wugongid == 80 and pid == 50 then
					probability[i] = 0
				end

				--��ҩʦ����������Ӣ
				if (wugongid == 12 or wugongid == 38) and pid == 57 then
					probability[i] = 0
				end

				--�ܲ�ͨ����̫��ȭ
				if wugongid == 16 and pid == 64 then
					probability[i] = 0
				end

				--��ʮ��ŷ���治�����˸��
				if (wugongid == 95 or wugongid == 104) and pid == 60 and WAR.ZDDH == 289 then
					probability[i] = 0
				end

				--��Ϧ��ӯӯ�������黭
				if (wugongid == 72 or wugongid == 84 or wugongid == 142) and pid == 611 then
					probability[i] = 0
				end

				--��Ϧ�������ô�
				if wugongid == 80 and pid == 612 then
					probability[i] = 0
				end

				--��Ϧ���ز��ý���
				if wugongid == 26 and pid == 613 then
					probability[i] = 0
				end

				--��Ϧ�����ŭ��������
				if wugongid == 45 and pid == 614 and WAR.LQZ[pid] == 100 then
					probability[i] = 0
				end

				--�������ֲ�������
				--��аս������������
				--��ʮ��������
				if wugongid == 103 and pid == 62 and (WAR.ZDDH == 275 or WAR.ZDDH == 277 or WAR.ZDDH == 289) then
					probability[i] = 0
				end

				--������赺�һ�������罣
				if wugongid == 44 and pid == 633 and WAR.ZDDH == 280 then
					probability[i] = 0
				end

				--����������˷ﲻ�ú���
				if wugongid == 67 and pid == 3 and WAR.ZDDH == 280 then
					probability[i] = 0
				end

				--��������������������������
				if pid == 22 and (wugongid == 30 or wugongid == 31 or wugongid == 32 or wugongid == 34) then
					probability[i] = 0
				end
			else
				probability[i] = 0		 --�Զ�����ɱ����
			end
		else
			wugongnum = i - 1
			break;
		end
	end

	if wugongnum ==  0 then			--���û���书��ֱ�ӷ���-1
		return -1;
	end

	local maxoffense = 0			--������󹥻���
	for i = 1, wugongnum do
		if maxoffense < probability[i] then
			maxoffense = probability[i]
		end
	end

	local mynum = 0					--�����ҷ��͵��˸���
	local enemynum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			if WAR.Person[i]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
				mynum = mynum + 1
			else
				enemynum = enemynum + 1
			end
		end
	end


	local factor = 0			--��������Ӱ�����ӣ����˶��������ȹ��������书��ѡ���������
	if mynum < enemynum then
		factor = 2
	else
		factor = 1
	end

	for i = 1, wugongnum do		--������������Ч��
		local wugongid = JY.Person[pid]["�书" .. i]
		if probability[i] > 0 then
			if probability[i] < maxoffense*3/4 then		--ȥ��������С���书
				probability[i] = 0
			else
				local level = math.modf(JY.Person[pid]["�书�ȼ�" .. i] / 100) + 1
				probability[i] = probability[i] + JY.Wugong[wugongid]["�ƶ���Χ".. level]  * factor*10
				if JY.Wugong[wugongid]["ɱ�˷�Χ" .. level] > 0 then
					probability[i] = probability[i] + JY.Wugong[wugongid]["ɱ�˷�Χ" .. level]* factor*10
				end
			end
		end
	end

	local s = {}			--���ո��������ۼ�
	local maxnum = 0
	for i = 1, wugongnum do
		s[i] = maxnum
		maxnum = maxnum + probability[i]
	end
	s[wugongnum + 1] = maxnum
	if maxnum == 0 then		--û�п���ѡ����书
		return -1
	end

	local v = Rnd(maxnum)		--���������
	local selectid = 0
	for i = 1, wugongnum do		--���ݲ������������Ѱ�������ĸ��书����
		if s[i] <= v and v < s[i + 1] then
			selectid = i
		end
	end
	return selectid
end

--ս���书ѡ��˵�
--sb starΪ�������������Ϊ��ֹ�����﷨��������
function War_FightMenu(sb, star, wgnum)
	local pid = WAR.Person[WAR.CurID]["������"]
	local numwugong = 0
	local menu = {}
	local canuse = {}
	local c = 0;
	for i = 1, CC.Kungfunum do
		local tmp = JY.Person[pid]["�书" .. i]
		if tmp > 0 then
			menu[i] = {JY.Wugong[tmp]["����"], nil, 1}

			--[[�ڹ��޷�����
			--��̹֮����
			if match_ID(pid, 48) == false and JY.Wugong[tmp]["�书����"] == 6 then
				menu[i][3] = 0
			end

			--�Ṧ�޷�����
			if JY.Wugong[tmp]["�书����"] == 7 then
				menu[i][3] = 0
			end

			--��ת���Ʋ���ʾ
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
		--Ϊ���˺�Ԥ������۽�������Ϊ���
		WAR.PREVIEW = pid
		JY.Person[pid]["�۽�����"] = JY.Person[pid]["�书" .. r]
		WAR.ShowHead = 0
		local r2 = War_Fight_Sub(WAR.CurID, r)
		WAR.PREVIEW = -1
		WAR.ShowHead = 1
		Cls()
		return r2
	--�޾Ʋ��������ֿ�ݼ�ֱ��ʹ���书
	else
		if wgnum <= c then
			WAR.PREVIEW = pid
			JY.Person[pid]["�۽�����"] = JY.Person[pid]["�书" .. canuse[wgnum]]
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

--�Զ�ս��ʱ ��˼��
--��ҩ��flag��2 ������3������4������6 �ⶾ
function War_Think()
	local pid = WAR.Person[WAR.CurID]["������"]
	local r = -1
	local minNeili = War_GetMinNeiLi(pid)
	local can_eat_drug = 0
	--���ҷ����ῼ�ǳ�ҩ
	if WAR.Person[WAR.CurID]["�ҷ�"] == false then
		can_eat_drug = 1
	--������ҷ���ֻ���ڶ�������Ż��ҩ
	else
		if inteam(pid) and JY.Person[pid]["�Ƿ��ҩ"] == 1 then
			can_eat_drug = 1
		end
	end
	--����������ս����ҩ
	if WAR.Person[WAR.CurID]["�ҷ�"] == false and WAR.ZDDH == 257 then
		can_eat_drug = 0
	end
	--���Գ�ҩ�Ļ�
	if can_eat_drug == 1 then
		--������ҩ
		local eat_eng_drug = 0
		if inteam(pid) then
			local fz = {50, 30, 10}
			if JY.Person[pid]["����"] < fz[JY.Person[pid]["������ֵ"]] then
				eat_eng_drug = 1
			end
		else
			if JY.Person[pid]["����"] < 10 then
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

		--��Ѫҩ
		local eat_hp_drug = 0
		if inteam(pid) then
			local fz = {0.7, 0.5, 0.3}
			if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"]*fz[JY.Person[pid]["������ֵ"]] then
				eat_hp_drug = 1
			end
		else
			--��������ȷ����Ѫҩ����
			local rate = -1
			if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 5 then
				rate = 90
			elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 4 then
				rate = 70
			elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 3 then
				rate = 50
			elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 2 then
				rate = 25
			end

			--����Ҳ���ӳ�Ѫҩ����
			if JY.Person[pid]["���˳̶�"] > 50 then
				rate = rate + 50
			end

			--����ʱ������ҩ
			if Rnd(100) < rate and WAR.LQZ[pid] ~= nil and WAR.LQZ[pid] ~= 100 then
				eat_hp_drug = 1
			end
		end
		if eat_hp_drug == 1 then
			r = War_ThinkDrug(2)
			if r >= 0 then				--�����ҩ��ҩ
				return r
			else
				r = War_ThinkDoctor()		--���û��ҩ������ҽ��
				if r >= 0 then
					return r
				end
			end
		end

		--������ҩ
		local eat_mp_drug = 0
		if inteam(pid) then
			local fz = {0.7, 0.5, 0.3}
			if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"]*fz[JY.Person[pid]["������ֵ"]] then
				eat_mp_drug = 1
			end
		else
			--��������
			local rate = -1
			if JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 6 then
				rate = 100
			elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 5 then
				rate = 75
			elseif JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 4 then
				rate = 50
			end

			if Rnd(100) < rate or minNeili > JY.Person[pid]["����"] then
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
		if CC.PersonAttribMax["�ж��̶�"] * 3 / 4 < JY.Person[pid]["�ж��̶�"] then
			jdrate = 60
		else
			if CC.PersonAttribMax["�ж��̶�"] / 2 < JY.Person[pid]["�ж��̶�"] then
				jdrate = 30
			end
		end

		--��Ѫ���³Խⶾҩ
		--��ŭ���Խⶾҩ
		if Rnd(100) < jdrate and JY.Person[pid]["����"] < JY.Person[pid]["�������ֵ"] / 2 and WAR.LQZ[pid] ~= nil and WAR.LQZ[pid] ~= 100 then
			r = War_ThinkDrug(6)
			if r >= 0 then
				return r
			end
		end
	end

	if inteam(pid) then
		if JY.Person[pid]["��Ϊģʽ"] == 4 then
			r = 0
		elseif JY.Person[pid]["��Ϊģʽ"] == 3 then
			r = 7
		elseif JY.Person[pid]["��Ϊģʽ"] == 2 then
			r = 8
		elseif JY.Person[pid]["��Ϊģʽ"] == 1 then
			if minNeili <= JY.Person[pid]["����"] and JY.Person[pid]["����"] > 10 then
				r = 1
			else
				r = 0
			end
		end
	else
		if minNeili <= JY.Person[pid]["����"] and JY.Person[pid]["����"] > 10 then
			r = 1
		else
			r = 0
		end
	end
	return r
end

--�Զ�����
function War_AutoFight()
	local pid = WAR.Person[WAR.CurID]["������"]
	local wugongnum;
	if inteam(pid) and JY.Person[pid]["����ʹ��"] ~= 0 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["�书"..i] == JY.Person[pid]["����ʹ��"] then
				wugongnum = i
				break
			end
		end
		--��һ����ֹ��ϴ��������
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

--�Զ�ս��
function War_Auto()
	local pid = WAR.Person[WAR.CurID]["������"]
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

--��������
function War_AddPersonLVUP(pid)
	local tmplevel = JY.Person[pid]["�ȼ�"]
	if CC.Level <= tmplevel then
		return false
	end
	if JY.Person[pid]["����"] < CC.Exp[tmplevel] then
		return false
	end
	while CC.Exp[tmplevel] <= JY.Person[pid]["����"] do
		tmplevel = tmplevel + 1
		if CC.Level <= tmplevel then
			break;
		end
	end

	DrawStrBoxWaitKey(string.format("%s ������", JY.Person[pid]["����"]), C_WHITE, CC.DefaultFont)
	--���������ĵȼ�
	local leveladd = tmplevel - JY.Person[pid]["�ȼ�"]

	JY.Person[pid]["�ȼ�"] = JY.Person[pid]["�ȼ�"] + leveladd

	--�����������
	AddPersonAttrib(pid, "�������ֵ", (JY.Person[pid]["��������"] + 4) * leveladd * 4)

	JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]
	JY.Person[pid]["����"] = CC.PersonAttribMax["����"]
	JY.Person[pid]["���˳̶�"] = 0
	JY.Person[pid]["�ж��̶�"] = 0

	local theadd = JY.Person[pid]["����"] / 4
	--�������������١�����
	--���������ĳɳ�
	AddPersonAttrib(pid, "�������ֵ", math.modf(leveladd * ((16 - JY.Person[pid]["��������"]) * 7 + 210 / (theadd + 1))))

	--�������ÿ�������50
	if pid == 0 and JY.Base["��׼"] == 6 then
	  AddPersonAttrib(pid, "�������ֵ", 50 * leveladd)
	end
	JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]

	--ѭ�������ȼ����ۼ�����
	for i = 1, leveladd do
		local ups;
		local p_zz = JY.Person[pid]["����"];
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

		--����� ���˻ظ�ǰ��ÿ��3��
		--[[
		if pid == 35 and GetD(82, 1, 0) == 1 then
			ups = 3
		end]]

		--���ѹ��� 20��֮��ÿ��6��
		if pid == 55 and JY.Person[pid]["�ȼ�"] > 20 then
			ups = 6
		end

		AddPersonAttrib(pid, "������", ups)
		AddPersonAttrib(pid, "������", ups)
		AddPersonAttrib(pid, "�Ṧ", ups)

		--�޸�ҽ�ơ��ö����ⶾ��������ȼ��ҹ�������
		if JY.Person[pid]["ҽ������"] >= 20 then
			AddPersonAttrib(pid, "ҽ������", 2)
		end
		if JY.Person[pid]["�ö�����"] >= 20 then
			AddPersonAttrib(pid, "�ö�����", 2)
		end
		if JY.Person[pid]["�ⶾ����"] >= 20 then
			AddPersonAttrib(pid, "�ⶾ����", 2)
		end

		--���ѳ¼��� ��������Χ
		if pid == 75 then
			if JY.Person[pid]["ȭ�ƹ���"] >= 0 then
				AddPersonAttrib(pid, "ȭ�ƹ���", (4 + math.random(0,1)))
			end
			if JY.Person[pid]["ָ������"] >= 0 then
				AddPersonAttrib(pid, "ָ������", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["��������"] >= 0 then
				AddPersonAttrib(pid, "��������", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["ˣ������"] >= 0 then
				AddPersonAttrib(pid, "ˣ������", (7 + math.random(0,1)))
			end
			if JY.Person[pid]["�������"] >= 0 then
				AddPersonAttrib(pid, "�������", (7 + math.random(0,1)))
			end
		end

		--����ÿ�����
		if JY.Person[pid]["��������"] >= 20 then
			AddPersonAttrib(pid, "��������", 2)
		end
	end

	local ey = 0  --ÿ�������ɵ���

	local n = ey*leveladd;		--��������������

	--�ӵ�
	local gj = JY.Person[pid]["������"];
	local fy = JY.Person[pid]["������"];
	local qg = JY.Person[pid]["�Ṧ"];
	local tmpN = n;

	--�츳ID
	local tfid;
	--����
	if pid == 0 then
		--����
		if JY.Base["��׼"] > 0 then
			tfid = 280 + JY.Base["��׼"]
		--����
		elseif JY.Base["����"] > 0 then
			tfid = 290
		--����
		else
			tfid = JY.Base["����"]
		end
	--����
	else
		tfid = pid
	end

	--�����ӵ����
	local current = 1
	while true do
		if JY.Restart == 1 then
			break
		end
		Cls();
		ShowPersonStatus_sub(pid, 1, 1, tfid, -17, 1)
		DrawString(CC.ScreenW/2-CC.Fontsmall*6-2,20,string.format("�ɷ��������%d ��",tmpN) ,C_ORANGE, CC.Fontsmall);
		for i = 1, 3 do
			local shade_color = C_GOLD
			if i ==  current then
				shade_color = PinkRed
			end
			DrawString(CC.ScreenW/2-CC.Fontsmall*7, 24+i*(CC.FontSmall4+CC.PersonStateRowPixel), "��",shade_color, CC.Fontsmall);
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
				if current == 1 and JY.Person[pid]["������"] > gj then
					JY.Person[pid]["������"] = JY.Person[pid]["������"]-1
					tmpN = tmpN+1
				elseif current == 2 and JY.Person[pid]["������"] > fy then
					JY.Person[pid]["������"] = JY.Person[pid]["������"]-1
					tmpN = tmpN+1
				elseif current == 3 and JY.Person[pid]["�Ṧ"] > qg then
					JY.Person[pid]["�Ṧ"] = JY.Person[pid]["�Ṧ"]-1
					tmpN = tmpN+1
				end
			elseif keypress == VK_RIGHT and tmpN > 0 then
				if current == 1 and JY.Person[pid]["������"] < 520 then
					JY.Person[pid]["������"] = JY.Person[pid]["������"]+1
					tmpN = tmpN-1
				elseif current == 2 and JY.Person[pid]["������"] < 520 then
					JY.Person[pid]["������"] = JY.Person[pid]["������"]+1
					tmpN = tmpN-1
				elseif current == 3 and JY.Person[pid]["�Ṧ"] < 520 then
					JY.Person[pid]["�Ṧ"] = JY.Person[pid]["�Ṧ"]+1
					tmpN = tmpN-1
				end
			elseif keypress==VK_SPACE or keypress==VK_RETURN then
				if tmpN == 0 or (JY.Person[pid]["������"] == 520 and JY.Person[pid]["������"] == 520 and JY.Person[pid]["�Ṧ"] == 520) then
					Cls();
					break
				else
					DrawStrBoxWaitKey("�Բ���"..JY.Person[pid]["����"].."����ʣ��ĵ���û��!", C_WHITE, CC.DefaultFont)
				end
			end
		end
	end
	return true
end

--ս������������
--isexp ����ֵ
--warStatus ս��״̬
function War_EndPersonData(isexp, warStatus)
	--�޾Ʋ�����Ѫ����ԭ����
	Health_in_Battle_Reset()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["������"]
		if WAR.Person[i]["�ҷ�"] == true and inteam(pid) then
			if WAR.Person[i]["����"] == false then
				WarReward(pid, WAR.ZDDH)
			elseif JY.Base["�Ѷ�"] > 1 then
				JY.Person[pid]["�������ֵ"] = 0
				JY.Person[pid]["�������ֵ"] = 0
				JY.Person[pid]["����"] = 0
				JY.Person[pid]["����"] = 0
			end
		end
	end

	--�޾Ʋ�����ս��״̬�ָ�
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["������"]
		--�з��ظ���״̬
		if not instruct_16(pid) then
			JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]
			JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]
			JY.Person[pid]["����"] = CC.PersonAttribMax["����"]
			JY.Person[pid]["���˳̶�"] = 0
			JY.Person[pid]["�ж��̶�"] = 0
			JY.Person[pid]["����̶�"] = 0
			JY.Person[pid]["���ճ̶�"] = 0
		--�ҷ��ָ�״̬
		else
			JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]
			JY.Person[pid]["����"] = JY.Person[pid]["�������ֵ"]
			JY.Person[pid]["����"] = CC.PersonAttribMax["����"]
			JY.Person[pid]["���˳̶�"] = 0
			JY.Person[pid]["�ж��̶�"] = 0
			JY.Person[pid]["����̶�"] = 0
			JY.Person[pid]["���ճ̶�"] = 0
			--������˹�����ֹͣ
			--[[
			if JY.Person[pid]["�����ڹ�"] ~= 0 then
				JY.Person[pid]["�����ڹ�"] = 0
			end
			if JY.Person[pid]["�����Ṧ"] ~= 0 then
				JY.Person[pid]["�����Ṧ"] = 0
			end]]
			--��սͳ��
			JY.Person[pid]["��ս"] = JY.Person[pid]["��ս"] + 1
		end
	end

	--�Ƿ��书�ظ�
	JY.Person[50]["�书1"] = 26
	JY.Wugong[13]["����"] = "����"

	--�Ħ���书�ָ�
	if JY.Base["����"] == 103 then
		JY.Person[0]["�书2"] = 98
	end

	--��ؤ�����
	if WAR.ZDDH == 82 then
		SetS(10, 0, 18, 0, 1)
	end

	--÷ׯ ͺ����ս����
	if WAR.ZDDH == 44 then
		instruct_3(55, 6, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
		instruct_3(55, 7, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

	--÷ׯ �ڰ���ս��
	if WAR.ZDDH == 45 then
		instruct_3(55, 9, 1, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

	--÷ׯ ���ӹ�ս��
	if WAR.ZDDH == 46 then
		instruct_3(55, 13, 0, 0, 0, 0, 0, -2, -2, -2, 0, -2, -2)
	end

  	--��������ս��ʤ��
	--�ö�����Ʒ�¼�¼
	if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and warStatus == 1 then
		JY.Person[27]["Ʒ��"] = 10
	end

	--ս��ʧ�ܣ������޾���
	if warStatus == 2 and isexp == 0 then
		return
	end

	--ͳ�ƻ������
	local liveNum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["�ҷ�"] == true and JY.Person[WAR.Person[i]["������"]]["����"] > 0 then
			liveNum = liveNum + 1
		end
	end

	--�������
	if WAR.ZDDH == 48 then
		SetS(57, 52, 29, 1, 0)
		SetS(57, 52, 30, 1, 0)
	--һ�ƾӣ�ŷ���棬��ǧ��
	elseif WAR.ZDDH == 175 then
		instruct_3(32, 12, 1, 0, 0, 0, 0, 0, 0, 0, -2, -2, -2)
	--�ƴ���
	elseif WAR.ZDDH == 82 then
		SetS(10, 0, 18, 0, 1)
	--ľ����
	elseif WAR.ZDDH == 214 then
		SetS(10, 0, 19, 0, 1)
	end

	if JY.Restart == 1 then
		return
	end
end
--��עһ��
function IsAlone(id)
	local alone = true
	for j = 0, WAR.PersonNum - 1 do
		if j ~= id and WAR.Person[j]["�ҷ�"] == WAR.Person[id]["�ҷ�"] and WAR.Person[j]["����"] == false then
			alone = false
		end
	end
	return alone
end
	
--ִ��ս�����Զ����ֶ�ս��������
--idս��������
--wugongnum ʹ�õ��书��λ��
--x,yΪս����������
function War_Fight_Sub(id, wugongnum, x, y)
	local pid = WAR.Person[id]["������"]
	local wugong = 0
	--JY.Person[pid]["����"] = wugongnum
	if wugongnum < 100 then
		wugong = JY.Person[pid]["�书" .. wugongnum]
	else
		wugong = wugongnum - 100
		--x = WAR.Person[WAR.CurID]["����X"] - x
		--y = WAR.Person[WAR.CurID]["����Y"] - y
		WarDrawMap(0)
		local fj = JY.Wugong[wugong]["����"] .. "-����"		

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

	WAR.WGWL = JY.Wugong[wugong]["������10"]
	local fightscope = JY.Wugong[wugong]["������Χ"]		--ûɶ�õ�����
	local kfkind = JY.Wugong[wugong]["�书����"]
	local level = 11   

	WAR.ShowHead = 0
	local m1, m2, m3, a1, a2 = WugongArea(wugong, level)  --��ȡ�书�ķ�Χ
	if GetWarMap(WAR.Person[id]["����X"], WAR.Person[id]["����Y"], 6) == 2 then
		a1 = 3
		a2 = a2 + 1
	end --��ɫ
	
	if IsAlone(id) then
		a1 = 3
		a2 = a2 + 1
	end
	local movefanwei = {m1, m2, m3}				--���ƶ��ķ�Χ
	local atkfanwei = {a1, a2}	--������Χ

	x, y = War_FightSelectType(movefanwei, atkfanwei, x, y, wugong)

	if x == nil then
		return 0
	end

	--�жϺϻ�
	local ZHEN_ID = -1

	--��������
	local fightnum = 1
	WAR.ACT = 1
	WAR.FLHS6 = 0	--��������

	local emeny = GetWarMap(x, y, 2)
	if emeny >= 0 and emeny ~= WAR.CurID then
		local pidq = JY.Person[pid]["�Ṧ"]
		local ljid = WAR.Person[emeny]["������"]
		local eidq = JY.Person[ljid]["�Ṧ"]
		fightnum = 1 + math.modf((pidq - eidq) / 20)
		fightnum = math.max(1, fightnum)
	end
	--�ж�����
	if JY.Person[pid]["���һ���"] == 1 and WAR.ZYHB == 0 then
		--�ж����ң�80-����
		local zyjl = 80 - JY.Person[pid]["����"]
		if zyjl < 0 then
			zyjl = 0
		end
		--�ܲ�ͨ100%
		if match_ID(pid, 64) then
			zyjl = 100
		end
		--����80%
		if match_ID(pid, 55) then
			zyjl = 80
		end
		--С��Ů70%
		if match_ID(pid, 59) then
			zyjl = 70
		end
		--���������Ѻ�70%
		if match_ID_awakened(pid, 631, 1) then
			zyjl = 70
		end
		--��Ϧ����100%
		--��Ϧ��Ů100%
		if match_ID(pid, 612) or match_ID(pid, 615) then
			zyjl = 100
		end
		--��ŭ������
		if WAR.LQZ[pid] == 100 then
			zyjl = 100
		end
		--�۽���Ӯ�ܲ�ͨ����+20%
		if pid == 0 and JY.Person[64]["�۽�����"] == 1 then
			zyjl = zyjl + 20
		end
		--����100%
		if zyjl > 100 then
			zyjl = 100
		end
		--��ת���Ʋ���������
		if JLSD(0, zyjl, pid) and WAR.DZXY == 0 then
			WAR.ZYHB = 1
			--�ĵ���Ч����4��ʾ
			if WAR.Person[WAR.CurID]["��Ч����4"] ~= nil then
				WAR.Person[WAR.CurID]["��Ч����4"] = WAR.Person[WAR.CurID]["��Ч����4"] .."�����һ���";
			else
				WAR.Person[WAR.CurID]["��Ч����4"] = "���һ���";
			end
		end
	end

	--�ܲ�ͨ����һ�����Һ��м��ʸ�������׷�ӵڶ������ң�����ר��
	if match_ID(pid, 64) and pid == 0 and WAR.ZYHB == 2 and WAR.ZHB == 0 then
		local zyjl = 80 - JY.Person[pid]["����"]
		if zyjl < 0 then
			zyjl = 0
		end
		--��ת���Ʋ���������
		if JLSD(0, zyjl, pid) and WAR.DZXY == 0 then
			WAR.ZYHB = 1
			WAR.ZHB = 1

			--�ĵ���Ч����4��ʾ
			if WAR.Person[WAR.CurID]["��Ч����4"] ~= nil then
				WAR.Person[WAR.CurID]["��Ч����4"] = WAR.Person[WAR.CurID]["��Ч����4"] .."�����һ���";
			else
				WAR.Person[WAR.CurID]["��Ч����4"] = "���һ���";
			end
		end
	end

	--[[��ת1��
	if WAR.DZXY == 1 then
		fightnum = 1
	end]]

  while WAR.ACT <= fightnum do
	if JY.Restart == 1 then
		break
	end
	lib.GetKey()
    if WAR.WS == 1 then		--����
		WAR.WS = 0
    end
    if WAR.BJ == 1 then		--����
		WAR.BJ = 0
    end
    if WAR.DJGZ == 1 then	--��������
		WAR.DJGZ = 0
    end
    if WAR.HQT == 1 then	--����ͩ ɱ����
		WAR.HQT = 0
    end
    if WAR.CY == 1 then		--��Ӣ ɱ����
		WAR.CY = 0
    end
    if WAR.HDWZ == 1 then	--��������϶�
		WAR.HDWZ = 0
    end

    WAR.NGJL = 0		--��ǰ�����ڹ����
    WAR.KHBX = 0		--������Ŀ
    WAR.LXZQ = 0
	WAR.LXYZ = 0
    WAR.GCTJ = 0
    WAR.ASKD = 0
    WAR.JSYX = 0
    WAR.BMXH = 0
    WAR.TD = -1
	WAR.TDnum = 0
    WAR.TZ_XZ = 0		--����ָ��
    WAR.JGZ_DMZ = 0		--��Ħ��
    WAR.LHQ_BNZ = 0		--������
	WAR.WD_CLSZ = 0		--��������
	WAR.TXZQ = {}		--̫��֮�������¼
    CleanWarMap(4, 0)

    WAR.L_TLD = 0		--װ����������Ч����Ѫ
	WAR.PJTX = 0 		--�������������������ƾ�����
	WAR.CXLC = 0		--���Ƴ�������
	WAR.FQY = 0			--����������ʤ����

	WAR.YTML = 0 		--��������
	WAR.JSTG = 0		--�����
	WAR.TXZZ = 0		--̫��֮��
	WAR.MMGJ = 0		--äĿ����
	WAR.JSAY = 0		--���߰���
	WAR.OYFXL = 0 		--ŷ������ݸ�����������˺�
	WAR.XDLeech = 0		--Ѫ����Ѫ��
	WAR.WYXLeech = 0	--ΤһЦ��Ѫ��
	WAR.TMGLeech = 0	--��ħ����Ѫ��
	WAR.XHSJ = 0		--Ѫ�������Ѫ��
	WAR.KMZWD = 0 		--�ܲ�ͨ����֮���
	WAR.LFHX = 0 		--�ֳ�Ӣ�����ѩ
	WAR.YNXJ = 0		--ز�ÿձ�
	WAR.HXZYJ = 0		--����֮һ��
	WAR.YYBJ = 0 		--���������಻��
	WAR.NGXS = 0		--�ڹ�������ϵ��
	WAR.TYJQ = 0		--������Ԫ����
	WAR.OYK = 0 		--ŷ��������ȭ
	WAR.JQBYH = 0		--�������������̺�
	WAR.LPZ = 0			--��ƽ֮����

	WAR.QQSH1 = 0		--�����黭֮������
	WAR.QQSH2 = 0		--�����黭֮��ʵ���
	WAR.QQSH3 = 0		--�����黭֮����������

	WAR.CMDF = 0		--���鵶��

	WAR.HTS = 0			--�������嶾���2-5������
	WAR.YZQS = 0		--һ������

	WAR.JJZC = 0		--�Ž��洫��4������������Ч�����������0

    WAR.L_QKDNY = {}	--���¼���Ǭ����Ų���Ƿ񱻷�����
	WAR.TXXS = {} 		--��Ч������ʾ

    WarDrawAtt(x, y, atkfanwei, 3)
    if ZHEN_ID >= 0 then
		local tmp_id = WAR.CurID
		WAR.CurID = ZHEN_ID
		WarDrawAtt(WAR.Person[ZHEN_ID]["����X"] + x0 - x, WAR.Person[ZHEN_ID]["����Y"] + y0 - y, atkfanwei, 3)
		WAR.CurID = tmp_id
    end

	local ng = 0

	--�������
    if WAR.BJ == 1 then
		WAR.Person[id]["��Ч����"] = 89		--������Ч����
		if match_ID(pid, 50) then			--�Ƿ���Ч����
			local r = nil
			r = math.random(3)
			if r == 1 then
				Set_Eff_Text(id,"��Ч����1","�̵����ۼ� �������� ��Ӣ��ŭ");
			elseif r == 2 then
				Set_Eff_Text(id,"��Ч����1","����ǧ��������");
			elseif r == 3 then
				Set_Eff_Text(id,"��Ч����1","�������� ����Ӣ����");
			end
		end
		--�ĳ���Ч����4��ʾ
		if WAR.Person[WAR.CurID]["��Ч����4"] ~= nil then
			WAR.Person[WAR.CurID]["��Ч����4"] = WAR.Person[WAR.CurID]["��Ч����4"] .."��".. "����"
		else
			WAR.Person[WAR.CurID]["��Ч����4"] = "����";
		end
    end

	--�����죬��ת������
	if PersonKF(pid, 95) and WAR.DZXY == 0 then
		if WAR.tmp[200 + pid] == nil then
			WAR.tmp[200 + pid] = 0
		elseif WAR.tmp[200 + pid] > 100 then
			ng = ng + WAR.tmp[200 + pid] * 10 + 1500

			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].. "��������"
			else
				WAR.Person[id]["��Ч����3"] = "������"
			end
			--ŷ��������˺�
			if match_ID(pid, 60) then
				WAR.OYFXL = WAR.tmp[200 + pid]
			end
			WAR.Person[id]["��Ч����"] = math.fmod(95, 10) + 85

			--������0
			WAR.tmp[200 + pid] = 0
		end
	end

	--�츳�⹦���100������
	if Given_WG(pid, wugong) then
		ng = ng + 100
	end

    --�޾Ʋ�����ʨ�Ӻ�
    if PersonKF(pid, 92) then
    	if WAR.Person[id]["��Ч����"] == -1 then
    		WAR.Person[id]["��Ч����"] = math.fmod(92, 10) + 85
    	end
    	local nl = JY.Person[pid]["����"];
    	local f = 0;
		local chance = 70
		local force = 100
		--�������Ч��
		if Curr_NG(pid, 92) then
			chance = 100
			force = 200
		end
		--һ������Ҫ���������2000����лѷֻҪ���������0����
		local neilicha = 2000
		if match_ID(pid, 13) then
			neilicha = 0
		end
		if math.random(100) <= chance or wugong == 92 then
			f = 1
		end
		if f == 1 then
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[j]["����"] == false and (nl - JY.Person[WAR.Person[j]["������"]]["����"]) > neilicha then
					WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - force
					if Curr_NG(pid, 92) then
						JY.Person[WAR.Person[j]["������"]]["���˳̶�"] = JY.Person[WAR.Person[j]["������"]]["���˳̶�"] + math.random(5, 9)
					end
				end
			end
			Set_Eff_Text(id,"��Ч����2","ʨ�Ӻ�");
		end
    end

    --����ķ����
	if pid==0 and JY.Person[pid]["�������"] > 0  then
    	local rate = limitX(math.modf(20 + (101-JY.Person[pid]["����"])/10 + JY.Person[pid]["ʵս"]/50 + JY.Person[pid]["������"]/40 + JY.Person[pid]["��ѧ��ʶ"]/10),0,100);
    	local low = 25;

    	--�����������Ӽ���
		low = low - JY.Base["��������"]

		local rf = 0
		local rh = 0
		local rl = 0
		local times = 1
		--���߶����ж�+ѭ�����Σ���һ�ο��Դ�������������Ч
		if JY.Base["��׼"] == 7 then
			times = 2
		end
		for i = 1, times do
			if JLSD(low, rate, pid) or (JY.Base["��׼"] == 7 and JLSD(low, rate, pid)) then
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

		--�伲���
    	if rf == 1 and JY.Base["��������"] >= 9 then
			WAR.Person[id]["��Ч����"] = 6
			Set_Eff_Text(id,"��Ч����2","�伲���");
			WAR.FLHS1 = 1
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
					WAR.Person[j].Time = WAR.Person[j].Time + 100
				end
				if WAR.Person[j].Time > 980 then
					WAR.Person[j].Time = 980
				end
			end
		end
		--�������
		if rh == 1 then
			WAR.Person[id]["��Ч����"] = 6
			Set_Eff_Text(id,"��Ч����2","�������");
			ng = ng + 3000
		end
		--��������
		if rl == 1 and JY.Person[pid]["�������"] == 2 and WAR.FLHS6 < 3 then
			WAR.Person[id]["��Ч����"] = 6
			Set_Eff_Text(id,"��Ч����2","��������");
			fightnum = fightnum + 1
			WAR.FLHS6 = WAR.FLHS6 + 1
    	end
    end

    --���ѧ�ᱱڤ��
    if (PersonKF(pid, 85) and JLSD(45, 75, pid)) or (Curr_NG(pid, 85) and JLSD(20, 70, pid)) then
		if WAR.Person[id]["��Ч����"] == -1 then
			WAR.Person[id]["��Ч����"] = math.fmod(85, 10) + 85
		end
		Set_Eff_Text(id,"��Ч����2","��ڤ��");
		WAR.BMXH = 1

		--��ڤ������
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["�书" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["�书" .. w] == 85 then
				JY.Person[pid]["�书�ȼ�" .. w] = JY.Person[pid]["�书�ȼ�" .. w] + 50
				if JY.Person[pid]["�书�ȼ�" .. w] > 999 then
					JY.Person[pid]["�书�ȼ�" .. w] = 999
				end
				break;
			end
		end
    end

    --���Ǵ󷨣��뱱ڤ����ͬʱ����
    if ((PersonKF(pid, 88) and JLSD(45, 75, pid)) or (Curr_NG(pid, 88) and JLSD(20, 70, pid))) and WAR.BMXH == 0 then
		if WAR.Person[id]["��Ч����"] == -1 then
			WAR.Person[id]["��Ч����"] = math.fmod(88, 10) + 85
		end
		Set_Eff_Text(id,"��Ч����2","���Ǵ�");
		WAR.BMXH = 2

		--���Ǵ�����
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["�书" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["�书" .. w] == 88 then
				JY.Person[pid]["�书�ȼ�" .. w] = JY.Person[pid]["�书�ȼ�" .. w] + 50
				if JY.Person[pid]["�书�ȼ�" .. w] > 999 then
					JY.Person[pid]["�书�ȼ�" .. w] = 999
				end
				break;
			end
		end
    end

    --������
    if ((PersonKF(pid, 87) and JLSD(45, 75, pid)) or (Curr_NG(pid, 87) and JLSD(20, 70, pid))) and WAR.BMXH == 0 then
		if WAR.Person[id]["��Ч����"] == -1 then
			WAR.Person[id]["��Ч����"] = math.fmod(87, 10) + 85
		end
		Set_Eff_Text(id,"��Ч����2","������");
		WAR.BMXH = 3

		--����������
		for w = 1, CC.Kungfunum do
			if JY.Person[pid]["�书" .. w] < 0 then
				break;
			end
			if JY.Person[pid]["�书" .. w] == 87 then
				JY.Person[pid]["�书�ȼ�" .. w] = JY.Person[pid]["�书�ȼ�" .. w] + 50
				if JY.Person[pid]["�书�ȼ�" .. w] > 999 then
					JY.Person[pid]["�书�ȼ�" .. w] = 999
				end
				break;
			end
		end
    end

	--�ɸ磬����+2000��
	if pid == 627 then
		ng = ng + 2000
	end

    --�Ƿ�
    if match_ID(pid, 50) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 1000
		if not inteam(pid) then
			ng = ng + 1000
		end
		WAR.Person[id]["��Ч����"] = 111
		if WAR.Person[id]["��Ч����2"] ~= nil then
			WAR.Person[id]["��Ч����2"] = WAR.Person[id]["��Ч����2"].."+������"
		else
			WAR.Person[id]["��Ч����2"] = "����������"
		end
    end

	--�Ħ��
	if match_ID(pid, 103) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = math.fmod(98, 10) + 85
		Set_Eff_Text(id, "��Ч����2", "��������")
	end

	--brolycjw: ���߹�
    if match_ID(pid, 69) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 67
		Set_Eff_Text(id,"��Ч����2","ؤ������");
    end

	--����
    if match_ID(pid, 18) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����2"] == nil then
			WAR.Person[id]["��Ч����2"] = "��Ԫ����������"
		else
			WAR.Person[id]["��Ч����2"] = WAR.Person[id]["��Ч����2"].."+��Ԫ������"
		end
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = "ħ�ࡤ����".."��"..WAR.Person[id]["��Ч����3"]
		else
			WAR.Person[id]["��Ч����3"] = "ħ�ࡤ����"
		end
    end

 	--������
    if match_ID(pid, 12) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["��Ч����"] = 67
		Set_Eff_Text(id,"��Ч����2","ӥ������");
    end

	--������
    if match_ID(pid, 22) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["��Ч����"] = 1
		Set_Eff_Text(id,"��Ч����2","��������");
    end

	--brolycjw: ��ҩʦ
    if match_ID(pid, 57) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 95
		Set_Eff_Text(id,"��Ч����2","���Ű���");
    end

	--brolycjw: л�̿�
    if match_ID(pid, 164) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["��Ч����"] = 23
		Set_Eff_Text(id,"��Ч����2","Ħ���ʿ");
    end

	--�ݳ���
    if match_ID(pid, 594) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 93
		Set_Eff_Text(id,"��Ч����2","�����Ὥ");
    end

	--Ľ�ݲ�
    if match_ID(pid, 113) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 93
		Set_Eff_Text(id,"��Ч����2","�κ�����");
    end

    --������ 
    if match_ID(pid, 26) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 6
		Set_Eff_Text(id,"��Ч����2","ħ�ۡ�����");
    end

	--������
    if match_ID(pid, 83) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 500
		if not inteam(pid) then
			ng = ng + 500
		end
		WAR.Person[id]["��Ч����"] =  92
		Set_Eff_Text(id,"��Ч����2","�������");
    end

	--��������ɳ����ÿɱһ����+200����
	if match_ID(pid, 47) then
		ng = ng + 200*WAR.MZSH
	end

    --����
    if match_ID(pid, 102) and (inteam(pid)==false or JLSD(20,70+JY.Base["��������"]+math.modf(JY.Person[pid]["ʵս"]/50),pid)) then
		ng = ng + 600
		if not inteam(pid) then
			ng = ng + 600
		end
		WAR.Person[id]["��Ч����"] = 23
		if math.random(2) == 1 then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = "�г��޳���˫�����١�"..WAR.Person[id]["��Ч����3"]
			else
				WAR.Person[id]["��Ч����3"] = "�г��޳���˫������"
			end
		else
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = "�ϱ��������Ǽٷǿա�"..WAR.Person[id]["��Ч����3"]
			else
				WAR.Person[id]["��Ч����3"] = "�ϱ��������Ǽٷǿ�"
			end
		end
    end

    --����ڹ����������ˣ�50%���ʷ������������
    if pid == 0 and JY.Base["��׼"] == 6 and kfkind == 6 and level == 11 then
		WAR.WS = 1
		if JLSD(25, 75, pid) then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."+���������"..JY.Wugong[wugong]["����"]
			else
				WAR.Person[id]["��Ч����3"] = "���������"..JY.Wugong[wugong]["����"]
			end
			ng = ng + JY.Wugong[wugong]["������10"]
		end
    end

	--��ת�����ǳ���Ч����
	--WAR.Person[id]["��Ч����"] = 107

    --ʹ�ý���ʮ����
    if wugong == 26 then
		--�Ƿ�س����⣬���߹���������ȭ����40%
		if match_ID(pid, 50) or ((match_ID(pid, 69) or match_ID(pid, 55) or (pid == 0 and JY.Base["��׼"] == 1)) and JLSD(30, 70, pid)) then
			Set_Eff_Text(id, "��Ч����3", XL18JY[math.random(8)])
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
		--������ʽ
		elseif myrandom(15 + (level), pid) then
			Set_Eff_Text(id, "��Ч����3", XL18[math.random(6)])
			ng = ng + 1500
			for i = 1, (1 + (level)) / 2 do
				for j = 1, (1 + (level)) / 2 do
					SetWarMap(WAR.Person[WAR.CurID]["����X"] + i * 2 - 1, WAR.Person[WAR.CurID]["����Y"] + j * 2 - 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["����X"] - i * 2 + 1, WAR.Person[WAR.CurID]["����Y"] + j * 2 - 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["����X"] + i * 2 - 1, WAR.Person[WAR.CurID]["����Y"] - j * 2 + 1, 4, 1)
					SetWarMap(WAR.Person[WAR.CurID]["����X"] - i * 2 + 1, WAR.Person[WAR.CurID]["����Y"] - j * 2 + 1, 4, 1)
				end
			end
		end
    end

	--��ڤ���⣬������40%���ʴ�������ŭ�س�����ڤ���ϱس�
	if wugong == 21 and level == 11 and pid == 0 and (match_ID(pid,647) or match_ID(pid,648) or WAR.LQZ[pid] == 100 or JLSD(30, 70, pid)) then
		Set_Eff_Text(id, "��Ч����1", "��ڤ����")
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

	--��Ȼ����
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

	--�����񽣣�50%���ʽ������̺�
	if wugong == 49 and JLSD(20,70,pid) then
		WAR.JQBYH = 1
		Set_Eff_Text(id, "��Ч����3", "�������̺�")
	end

	--ʹ��������
    if wugong == 49 then
		local jl = 0
    	--ѧ��һ��ָ
     	if PersonKF(pid, 17) then
			jl = jl + 30
		end
		if myrandom(level+jl, pid) or (match_ID(pid, 53) and myrandom(level+jl, pid)) then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "��" ..LMSJ[math.random(6)]
			else
				WAR.Person[id]["��Ч����3"] = LMSJ[math.random(6)]
			end
			ng = ng + 2000
			if match_ID(pid, 53) then
				WAR.LMSJwav = 1
				WAR.WS = 1
			end
		end
    end


    --�޺�ȭ���׽���������ƣ�60%���ʣ��з��س�
    if wugong == 1 and PersonKF(pid, 108) then
    	if inteam(pid) == false or JLSD(20, 80, pid) then
     	 	WAR.LHQ_BNZ = 1
    	end
    end

    --��������ƣ��׽������Ħ�ƣ�40%���ʣ��з��س�
    if wugong == 22 and PersonKF(pid, 108)  then
    	if inteam(pid) == false or JLSD(40, 80, pid) then
			WAR.JGZ_DMZ = 1
    	end
    end

	--�嶾���ƣ���Ī������70%���ʱ��������
    if wugong == 3 and match_ID(pid, 161) and JLSD(10, 80, pid) then
		WAR.WD_CLSZ = 1
    end

    --ͭ����9��ǿ��ͭ�ˣ�ֱ�Ӵ�����Ħ��
    if pid > 480 and pid < 490 then
		WAR.Person[id]["��Ч����2"] = "�׽����"
		ng = ng + 1200
		WAR.JGZ_DMZ = 1
    end

    --ʯ���죬̫���񹦣�׷������
    if match_ID(pid, 38) and wugong == 102 and level == 11 then
		WAR.Person[id]["��Ч����3"] = XKXSJ[math.random(4)]
		ng = ng + 1500
    end

    --���ƣ����գ�׷������
    if match_ID(pid, 37) and wugong == 94 and level == 11 then
		WAR.Person[id]["��Ч����3"] = "���վ�����Ӱ��ȭ"
		ng = ng + 1000
    end

    --С�ѣ�ʥ��׷������
    if match_ID(pid, 66) and wugong == 93 and level == 11 then
		local zs = {"��ɳ���罵�Ļ�","����δ�����ӻ�","����嫹�ɳ�ٺ�","ҵ�����������"}
		WAR.Person[id]["��Ч����3"] = zs[math.random(4)]
		ng = ng + 1200
    end

    --��ҽ�����Ϊ������Ϻ��ҵ����� 60%�����ϱ�
    if wugong == 44 and level == 11 and math.random(10) < 7 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["�书" .. i] == 67 and JY.Person[pid]["�书�ȼ�" .. i] == 999 then
				Set_Eff_Text(id, "��Ч����1", "�����罣 �����һ")
				WAR.Person[id]["��Ч����"] = 6
				WAR.DJGZ = 1
				ng = ng + 1500
				break
			end
		end
    end

    --���ҵ�����Ϊ���������ҽ����� 60%�����ϱ�
    if wugong == 67 and level == 11 and math.random(10) < 7 then
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["�书" .. i] == 44 and JY.Person[pid]["�书�ȼ�" .. i] == 999 then
				Set_Eff_Text(id, "��Ч����1", "�����罣 �����һ")
				WAR.Person[id]["��Ч����"] = 6
				WAR.DJGZ = 1
				ng = ng + 1500
				break
			end
		end
    end

	--����������ϣ�����+1000
	if (wugong == 3 or wugong == 9 or wugong == 5 or wugong == 21 or wugong == 118) and ZiqiTL(pid) then
		ng = ng + 1000
		Set_Eff_Text(id, "��Ч����1", "��������")
	end

	--�޾Ʋ�����������ϼ��50%���ʽ�ϵ����+1000
	if Curr_NG(pid, 89) and kfkind == 3 and JLSD(20, 70, pid) then
		ng = ng + 1000
		Set_Eff_Text(id, "��Ч����3", "��ϼ����")
	end

	--�ƾ����£�����1000������
	if WAR.PJTX == 1 then
		ng = ng + 1000
	end

	--װ��ԧ�쵶��5����ʼ������׷��500����
	if JY.Person[pid]["����"] == 217 and wugong == 62 and JY.Thing[217]["װ���ȼ�"] >=5 then
		ng = ng + 500
	end
	if JY.Person[pid]["����"] == 218 and wugong == 62 and JY.Thing[218]["װ���ȼ�"] >=5 then
		ng = ng + 500
	end

	--����������ϣ�50%���ʶ�������+1000����ŭ�ط���
	if wugong >= 30 and wugong <= 34 and WuyueJF(pid) and (WAR.LQZ[pid] == 100 or JLSD(20, 70, pid))then
		ng = ng + 1000
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = "����������"..WAR.Person[id]["��Ч����3"]
		else
			WAR.Person[id]["��Ч����3"] = "��������"
		end
	end

	--�����黭��������ʽ������ɱ��
	if wugong == 72 and QinqiSH(pid) then
		ng = ng + 1200
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "�����һ��"
		else
			WAR.Person[id]["��Ч����3"] = "���һ��"
		end
		--50%���ʴ����ٴ�׷��ɱ��
		if JLSD(20, 70, pid) then
			ng = ng + 1000
			if WAR.Person[id]["��Ч����1"] ~= nil then
				WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "�������岼"
			else
				WAR.Person[id]["��Ч����1"] = "�����岼"
			end
		end
    end

	--���鵶����30%���ʣ�����ɱ�����ض���Ѫ
	--���������ж�
	if wugong == 153 and (JLSD(30, 60, pid) or (pid == 0 and JY.Base["��׼"] == 4 and JLSD(30,60,pid))) then
		WAR.CMDF = 1
		ng = ng + 1000
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "���߶�����"
		else
			WAR.Person[id]["��Ч����1"] = "�߶�����"
		end
	end

	--�������������+1000
	if WAR.NGJL == 103 then
		ng = ng + 1000
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+" .."����֮��"
		else
			WAR.Person[id]["��Ч����1"] = "����֮��"
		end
	end

	--��������������׷������1000��
	if match_ID(pid, 129) and WAR.CYZX[pid] ~= nil and WAR.BDQS > 0 then
		ng = ng + 1000
		local BDQS = {"����", "���", "����", "��Ȩ", "���", "����", "ҡ��"}
		if WAR.Person[id]["��Ч����2"] ~= nil then
			WAR.Person[id]["��Ч����2"] = WAR.Person[id]["��Ч����2"] .. "+" .."����������"..BDQS[WAR.BDQS]
		else
			WAR.Person[id]["��Ч����2"] = "����������"..BDQS[WAR.BDQS]
		end
	end

	--����ȭ�������������17��
	--лѷ�س�
	if wugong == 23 and (match_ID(pid, 13) or WAR.LQZ[pid] == 100 or JLSD(30, 60, pid))then
		WAR.YZQS = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+һ������"
		else
			WAR.Person[id]["��Ч����1"] = "һ������"
		end
	end

    --���� ʹ������������͵�ԣ�������ֿտ�Ҳ��
    if (match_ID(pid, 90) and wugong == 113) or (match_ID(pid, 131) and wugong == 116) then
		WAR.TD = -2
		--�����壺��սս������͵����
		if WAR.ZDDH == 226 or WAR.ZDDH == 79 then
			WAR.TD = -1;
		end
    end

	--��Զ��ʹ��̫��ȭ��̫�����������Զ��������״̬
	if match_ID(pid, 171) and (wugong == 16 or wugong == 46) then
		WAR.WDRX = 1
	end

    --��ҩʦ����һ�ι�����������500����������500׷���˺�
    if match_ID(pid, 57) and WAR.ACT == 1 then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				if JY.Person[WAR.Person[j]["������"]]["����"] > 500 then
					JY.Person[WAR.Person[j]["������"]]["����"] = JY.Person[WAR.Person[j]["������"]]["����"] - 500
					WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - 500;
				else
					WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - JY.Person[WAR.Person[j]["������"]]["����"];
					JY.Person[WAR.Person[j]["������"]]["����"] = 0
					--�޾Ʋ�������¼����Ѫ��
					WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["������"]]["����"]
					JY.Person[WAR.Person[j]["������"]]["����"] = JY.Person[WAR.Person[j]["������"]]["����"] - 100*JY.Person[WAR.Person[j]["������"]]["Ѫ������"]
					WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - 100*JY.Person[WAR.Person[j]["������"]]["Ѫ������"];
				end
				WAR.TXXS[WAR.Person[j]["������"]] = 1
			end
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+" .."ħ�����̺�������"
		else
			WAR.Person[id]["��Ч����1"] = "ħ�����̺�������"
		end
		WAR.Person[id]["��Ч����"] = 39
    end

	--�������嶾���2-5������
	if match_ID(pid, 83) and wugong == 3 then
		WAR.HTS = math.random(2, 5)
    end

    --���� ������
    if match_ID(pid, 92) then
		WAR.WS = 1
    end

    --ŷ���� ������
    if match_ID(pid, 60) then
		WAR.WS = 1
    end

    --�������� ������
    if match_ID(pid, 27) then
		WAR.WS = 1
    end

	--ɨ�� ������
    if match_ID(pid, 114) then
		WAR.WS = 1
    end

	--���࣬ԽŮ������
	if match_ID(pid, 604) and wugong == 156 then
		WAR.WS = 1
	end

	--���ɽ�ħս������������
	if match_ID(pid, 592) and WAR.ZDDH == 291 then
		WAR.WS = 1
	end

    --�Ƿ壬���������߹���ʹ�ý���ʮ���� ������
    if (match_ID(pid, 50) or match_ID(pid, 55) or match_ID(pid, 69)) and wugong == 26 then
		WAR.WS = 1
    end

    --���л�ʹ�÷��޵��� ������
    if match_ID(pid, 77) and wugong == 62 then
		WAR.WS = 1
    end

    --����� ����֮��ʹ�ö��¾Ž� ������
    if match_ID_awakened(pid, 35, 2) and wugong == 47 then
		WAR.WS = 1
    end

	--��Ů���Ľ� ������
	if wugong == 139 then
		WAR.WS = 1
	end

    --���ַ��� ����+2500
    if match_ID(pid, 62) then
		ng = ng + 2500
    end

    --���� ����+1000
    if match_ID(pid, 84) then
		ng = ng + 1000
    end

    --�����ɣ�ʹ����ƽǹ��������+1500
    if match_ID(pid, 52) and wugong == 70 then
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+" .."��ƽ��ǹ"
		else
			WAR.Person[id]["��Ч����3"] = "��ƽ��ǹ"
		end
		ng = ng + 1500
    end

    --����ͩ��ʹ�����ֽ�����������
    if match_ID(pid, 74) and wugong == 29 then
		WAR.HQT = 1
    end

    --��Ӣ��ʹ�����｣����ɱ����300
    if match_ID(pid, 63) and wugong == 38 then
		WAR.CY = 1
    end

    --��� �������Ǻ� ȫ�弯����100
    if match_ID(pid, 58) and WAR.XK ~= 2 then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - 100
			end
		end
		if WAR.Person[id]["��Ч����"] == nil then
			WAR.Person[id]["��Ч����"] = 89
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+" .."����֮ŭХ"
		else
			WAR.Person[id]["��Ч����1"] = "����֮ŭХ"
		end
    end

    --�����
    if WAR.XK == 2 and match_ID(pid, 58) and WAR.Person[WAR.CurID]["�ҷ�"] == WAR.XK2 then
		for e = 0, WAR.PersonNum - 1 do
			if WAR.Person[e]["����"] == false and WAR.Person[e]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				WAR.Person[e].TimeAdd = WAR.Person[e].TimeAdd - math.modf(JY.Person[WAR.Person[WAR.CurID]["������"]]["����"] / 5)
				if WAR.Person[e].Time < -450 then
					WAR.Person[e].Time = -450
				end
				JY.Person[WAR.Person[e]["������"]]["����"] = JY.Person[WAR.Person[e]["������"]]["����"] - math.modf(JY.Person[WAR.Person[WAR.CurID]["������"]]["����"] / 5)
				if JY.Person[WAR.Person[e]["������"]]["����"] < 0 then
					JY.Person[WAR.Person[e]["������"]]["����"] = 0
				end
				JY.Person[WAR.Person[e]["������"]]["����"] = JY.Person[WAR.Person[e]["������"]]["����"] - math.modf(JY.Person[WAR.Person[WAR.CurID]["������"]]["����"] / 25)
			end
			if JY.Person[WAR.Person[e]["������"]]["����"] < 0 then
				JY.Person[WAR.Person[e]["������"]]["����"] = 0
			end
		end

		--���֮������Ϊ0���������ֵ-1000��������������������
		if inteam(pid) then
			JY.Person[pid]["����"] = 0
			JY.Person[pid]["�������ֵ"] = JY.Person[pid]["�������ֵ"] - 1000
			JY.Person[300]["����"] = JY.Person[300]["����"] + 1
		else
			AddPersonAttrib(pid, "����", -1000)  --���з�����ֻ��1000
		end

		if JY.Person[pid]["�������ֵ"] < 500 then
			JY.Person[pid]["�������ֵ"] = 500
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+" .."����֮��ŭ��������Х"
		else
			WAR.Person[id]["��Ч����1"] = "����֮��ŭ��������Х"
		end
		WAR.Person[id]["��Ч����"] = 6
		WAR.XK = 3
	end

    --��ӯӯ��ʹ�ó����٣�60%�������ν���
    if match_ID(pid, 73) and wugong == 73 and math.random(10) < 7 then
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+" .."�������ν���"
		else
			WAR.Person[id]["��Ч����3"] = "�������ν���"
		end
		WAR.Person[id]["��Ч����"] = 89
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				WAR.TXXS[WAR.Person[j]["������"]] = 1
				--�޾Ʋ�������¼����Ѫ��
				WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["������"]]["����"]
				JY.Person[WAR.Person[j]["������"]]["����"] = JY.Person[WAR.Person[j]["������"]]["����"] - 50*JY.Person[WAR.Person[j]["������"]]["Ѫ������"]
				WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - 50*JY.Person[WAR.Person[j]["������"]]["Ѫ������"]
				--��˯״̬�ĵ��˻�����
				if WAR.CSZT[WAR.Person[j]["������"]] ~= nil then
					WAR.CSZT[WAR.Person[j]["������"]] = nil
				end
			end
		end
	end

	--�������� �����ٻ�Ѫ5%������10����
	if wugong == 73 and JiandanQX(pid) then
		Set_Eff_Text(id, "��Ч����3", "����������")
		WAR.Person[id]["��Ч����"] = 89
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", JY.Person[pid]["����"]*0.05)
		WAR.Person[WAR.CurID]["���˵���"] = (WAR.Person[WAR.CurID]["���˵���"] or 0) + AddPersonAttrib(pid, "���˳̶�", -10)
	end

	--��Ϧ��ӯӯ��ǿ��Ч��
    if match_ID(pid, 611) and wugong == 73 then
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+" .."ħ���ѻ�"
		else
			WAR.Person[id]["��Ч����3"] = "ħ���ѻ�"
		end
		WAR.Person[id]["��Ч����"] = 89
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				JY.Person[WAR.Person[j]["������"]]["����"] = JY.Person[WAR.Person[j]["������"]]["����"] - 100*JY.Person[WAR.Person[j]["������"]]["Ѫ������"]
			end
		end
	end

    --������ ����Ȼ��������500��ʼ
    if match_ID(pid, 5) and math.random(10) < 8 then
		WAR.ZSF = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+" .."����Ȼ"
		else
			WAR.Person[id]["��Ч����1"] ="����Ȼ"
		end
    end

    --����  ����ӻ���������200��ʼ
    if match_ID(pid, 49) and math.random(10) < 7 then
		WAR.XZZ = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .."+".."����ӻ�"
		else
			WAR.Person[id]["��Ч����1"] = "����ӻ�"
		end
    end

	--�ⲻƽ���콣��ʹ�ý�������
    if match_ID(pid, 142) and kfkind == 3 then
		WAR.KFKJ = 1
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .."+".."���콣"
		else
			WAR.Person[id]["��Ч����3"] = "���콣"
		end
    end

	--�Ž��洫������ʽ�����������+200
	if WAR.JJZC == 4 and pid == 0 then
		WAR.JJDJ = 1
	end

    --��������  ������Ѩ�֣�����+1000
	--����س���Ѩ��
    if (match_ID(pid, 27) and math.random(10) < 7) or (WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and pid == 27) then
		ng = ng + 1000
		WAR.BFX = 1
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+" .."������Ѩ��"
		else
			WAR.Person[id]["��Ч����3"] = "������Ѩ��"
		end
    end

    --������ ����ȫ���ж�+20
	--�۳���ǰѪ��7%
    if match_ID(pid, 2) then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				local loss = math.modf(JY.Person[WAR.Person[j]["������"]]["����"]*0.07)
				--�޾Ʋ�������¼����Ѫ��
				WAR.Person[j]["Life_Before_Hit"] = JY.Person[WAR.Person[j]["������"]]["����"]
				JY.Person[WAR.Person[j]["������"]]["����"] = JY.Person[WAR.Person[j]["������"]]["����"] - loss
				WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - loss
				WAR.Person[j]["�ж�����"] = (WAR.Person[j]["�ж�����"] or 0) + AddPersonAttrib(WAR.Person[j]["������"], "�ж��̶�", 20)
				WAR.TXXS[WAR.Person[j]["������"]] = 1
				--��˯״̬�ĵ��˻�����
				if WAR.CSZT[WAR.Person[j]["������"]] ~= nil then
					WAR.CSZT[WAR.Person[j]["������"]] = nil
				end
			end
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .."+".."���ĺ���"
		else
			WAR.Person[id]["��Ч����1"] = "���ĺ���"
		end
		WAR.Person[id]["��Ч����"] = 64
    end

    --�Ħ��  ʹ�û��浶����������30����ɱ����1000
    --��ͨ��ɫʹ����30%�Ļ���
	--���������ж�
    if wugong == 66 and level == 11 and (match_ID(pid, 103) or JLSD(30,60,pid) or (pid == 0 and JY.Base["��׼"] == 4 and JLSD(30,60,pid)))  then
		for j = 0, WAR.PersonNum - 1 do
			if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
				WAR.Person[j]["���˵���"] = (WAR.Person[j]["���˵���"] or 0) + AddPersonAttrib(WAR.Person[j]["������"], "���˳̶�", 30)
				WAR.TXXS[WAR.Person[j]["������"]] = 1
			end
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .."+".."�������ڡ����浶"
		else
			WAR.Person[id]["��Ч����1"] = "�������ڡ����浶"
		end
		WAR.Person[id]["��Ч����"] = 58
		ng = ng + 1000
    end

	--�޺���ħ����������Ч
	--ͬʱѧ���׽���+�޺���ħ���������׽��񹦱س����޺���ħ����Ч
	if WAR.NGJL == 96 or (Curr_NG(pid, 108) and PersonKF(pid, 96)) then
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+�޺���ħ";
		else
			WAR.Person[id]["��Ч����1"] = "�޺���ħ"
		end
	end

    --̫��ȭ����������
    if wugong == 16 then
		if WAR.tmp[3000 + pid] == nil then
			WAR.tmp[3000 + pid] = 0
		elseif 0 < WAR.tmp[3000 + pid] then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."����������"
			else
				WAR.Person[id]["��Ч����3"] = "��������"
			end
			ng = ng + WAR.tmp[3000 + pid]
		end
    end

	--��ɽ��÷�֣�ɱ�����
	if wugong == 14 then
		local exng = 0
		local CN_num = {"һ", "��", "��", "��", "��", "��", "��", "��", "��", "ʮ", "ʮһ","ʮ��"}
		for i = 1, CC.Kungfunum do
			if JY.Person[pid]["�书"..i] ~= 14 and JY.Person[pid]["�书�ȼ�"..i] == 999 then
				ng = ng + 100
				exng = exng + 1
			end
		end
		if exng > 0 then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."+��ɽ��÷"..CN_num[exng]
			else
				WAR.Person[id]["��Ч����3"] = "��ɽ��÷"..CN_num[exng]
			end
		end
	end

    --����ʹ����ɽ�����ƻ���÷�֣�����������ɱ����+1700
    if (wugong == 8 or wugong == 14) and match_ID(pid, 49) and PersonKF(pid, 101) and (JLSD(20, 80, pid) or WAR.NGJL == 98) then
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."+���չ���ѧ��������"
		else
			WAR.Person[id]["��Ч����3"] = "���չ���ѧ��������"
		end
		ng = ng + 1700
		WAR.TZ_XZ = 1
    end

    --�����壺������ʹ����ϵ����60%�Ļ��ʴ����ɱ����
    if match_ID(pid, 590) and kfkind == 5 and JLSD(20, 80, pid) then
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."+".."�������塤��������"
		else
			WAR.Person[id]["��Ч����3"] = "�������塤��������"
		end
    	ng = ng + 1200
    end

	--��������������
	local YufaJC = 0
	for i = 0, WAR.PersonNum - 1 do
		local yfid = WAR.Person[i]["������"]
		if WAR.Person[i]["����"] == false and WAR.Person[i]["�ҷ�"] and match_ID(yfid, 76) and Xishu_sum(yfid) >= 500 and inteam(pid) == false then
			YufaJC = 1
			break
		end
	end

	--�书��ʽ��ɱ����
	if YufaJC == 0 then
		--�������ŭ�Ž���������ʤ����
		if match_ID(pid, 140) and wugong == 47 and WAR.LQZ[pid] == 100 then
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."��".."����ʤ����"
			else
				WAR.Person[id]["��Ч����3"] = "����ʤ����"
			end
			ng = ng + 2000
			WAR.FQY = 1
		--����û����ʽ
		elseif CC.KFMove[wugong] ~= nil then
			--npc�س��У�С���๦�����س���ʽ����ŭ�س���ʽ����а�س���
			if inteam(pid) == false or myrandom(level, pid) or WAR.NGJL == 98 or WAR.LQZ[pid] == 100 or (wugong == 48 and level == 11 and WAR.DZXY == 0) then
				local num
				if wugong == 48 and inteam(pid) and WAR.DZXY ~= 1 and WAR.AutoFight == 0 then	--��а��ʽ�̶�
					num = WAR.BXZS
				else
					num = math.random(#CC.KFMove[wugong])										--������������ȡһ��
				end
				if WAR.Person[id]["��Ч����3"] ~= nil then
					WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"].."��"..CC.KFMove[wugong][num][1]
				else
					WAR.Person[id]["��Ч����3"] = CC.KFMove[wugong][num][1]
				end
				ng = ng + CC.KFMove[wugong][num][2]
			end
		end
	end

	--�����ᣬ40%��������1000����
    if match_ID(pid, 5) and WAR.Person[id]["��Ч����3"] ~= nil and JLSD(30, 70, pid) then
		WAR.Person[id]["��Ч����3"] = "����Ϊ��" .. "��" .. WAR.Person[id]["��Ч����3"]
		ng = ng + 1000
    end

	--��������ȫ�潣����60%������������777����
	if wugong == 39 and match_ID(pid, 129) and JLSD(20, 80, pid) then
		ng = ng + 777
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = "����������"..WAR.Person[id]["��Ч����3"]
		else
			WAR.Person[id]["��Ч����3"] = "��������"
		end
	end

	--��ָ��ͨ������һ�����������+1000
	if wugong == 18 and TaohuaJJ(pid) then
		ng = ng + 1000
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "����Ӱ��ʯ"
		else
			WAR.Person[id]["��Ч����3"] = "��Ӱ��ʯ"
		end
	end

	--л���ƣ���������
    if match_ID(pid, 596) then
		local WZTS = {"һ������","����ִ��","�������","��ľ�ɷ�","������˥","�����徻","��������","��������","�������"}
		local JTYL = math.random(9)
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+����һ����"..WZTS[JTYL]
		else
			WAR.Person[id]["��Ч����3"] =  "����һ����"..WZTS[JTYL]
		end
    end

    --�򹷰��� ����
    if wugong == 80 and level == 11 and (WAR.LQZ[pid] == 100 or JLSD(30, 70, pid) or (pid == 0 and JY.Base["��׼"] == 5 and JLSD(30, 75, pid))) then
		WAR.Person[id]["��Ч����3"] = "�򹷰�����ѧ--�����޹�"
		WAR.Person[id]["��Ч����"] = 89
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

    --�����壺���ҵ���������
    --��ϵ����40%�����50%����ŭ�س�
    if wugong == 67 and level == 11 and ((pid == 0 and JY.Base["��׼"] == 4 and (WAR.LQZ[pid] == 100 or JLSD(30,70,pid))) or (match_ID(pid, 1) and (WAR.LQZ[pid] == 100 or JLSD(20,70,pid)))) then
		local HDJY = {"���⡤����ʽ","���⡤�ݷ�����","���⡤���ֲص�","���⡤ɳŸ�Ӳ�","���⡤�ΰݱ���","���⡤�������ȵ�","���⡤����ժ�ĵ�","���⡤����������","���⡤�˷��ص�ʽ"};
		WAR.Person[id]["��Ч����3"] = HDJY[math.random(9)];
		WAR.Person[id]["��Ч����"] = 6
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

    --�������񣬱������� ��������
	--����ʽʱ�ش�������ŭʱ�س�
    if wugong == 45 and level == 11 and (match_ID(pid, 58) or match_ID(pid, 628) or (pid == 0 and JY.Base["��׼"] == 3)) and (WAR.LQZ[pid] == 100 or WAR.Person[id]["��Ч����3"] == nil) then
		WAR.Person[id]["��Ч����3"] = "�ؽ��洫������ɽӿ�����"
		WAR.Person[id]["��Ч����"] = 84
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

    --�����������ж�+13~16
    if match_ID(pid, 84) and math.random(10) < 7 then
		WAR.HDWZ = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"].."+".."���������ж�"
		else
			WAR.Person[id]["��Ч����1"] = "���������ж�"
		end
		WAR.Person[id]["��Ч����"] = 89
    end

    --������ ��Ŀ
    if wugong == 48 and PersonKF(pid, 105) then
		WAR.KHBX = 2
		WAR.Person[id]["��Ч����1"] = "���а������������Ŀ";
		WAR.Person[id]["��Ч����"] = 6
    end

	--�������߱ش�Ŀ
	if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and pid == 27 then
		WAR.KHBX = 2
		WAR.Person[id]["��Ч����1"] = "��������������Ŀ";
		WAR.Person[id]["��Ч����"] = 6
	end

    --äĿ״̬��20%���ʹ�����Ч
    if WAR.KHCM[pid] == 2 and math.random(10) <= 2 then
		WAR.MMGJ = 1
		WAR.Person[id]["��Ч����"] = 89
		WAR.Person[id]["��Ч����2"] = "äĿ״̬��������Ч"
    end

	--Ԭ��־���Ѻ���������30%��50%���ʳ����߰���
	if match_ID_awakened(pid, 54, 1) and wugong == 40 and JY.Person[pid]["����"] <= (JY.Person[pid]["�������ֵ"]*0.3) and JLSD(20,70,pid) then
		WAR.JSAY = 1
		ng = ng + 2000
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[i]["����"] == false then
				local offset1 = math.abs(WAR.Person[WAR.CurID]["����X"] - WAR.Person[i]["����X"])
				local offset2 = math.abs(WAR.Person[WAR.CurID]["����Y"] - WAR.Person[i]["����Y"])
				if offset1 <= 8 and offset2 <= 8 then
					SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 4, 1)
				end
			end
		end
	end

    local pz = math.modf(JY.Person[0]["����"] / 10)

    --���ǽ�����У�ȫ������
    if pid == 0 and JY.Base["��׼"] == 3 and 120 <= TrueYJ(pid) and 0 < JY.Person[pid]["�书9"] and kfkind == 3 and wugong ~= 43 and JLSD(25, 60 + pz, pid) and JY.Person[pid]["�������"] > 0 then
		CleanWarMap(4, 0)
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[i]["����"] == false then
				SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 4, 1)
			end
		end
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[3]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[3] .. "��" .. WAR.Person[id]["��Ч����3"]
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

    --����ȭϵ����
    if pid == 0 and JY.Base["��׼"] == 1 and 0 < JY.Person[pid]["�书9"] and 120 <= TrueQZ(pid) and JLSD(25, 60 + pz, pid) and kfkind == 1 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[1]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[1] .. "��" .. WAR.Person[id]["��Ч����3"]
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

    --����ָ������
    if pid == 0 and JY.Base["��׼"] == 2 and 0 < JY.Person[pid]["�书9"] and 120 <= TrueZF(pid) and JLSD(25, 60 + pz, pid) and kfkind == 2 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[2]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[2] .. "��" .. WAR.Person[id]["��Ч����3"]
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

    --������ϵ����
    if pid == 0 and JY.Base["��׼"] == 5 and 0 < JY.Person[pid]["�书9"] and 120 <= JY.Person[pid]["�������"] and JLSD(25, 65 + pz, pid) and kfkind == 5 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[5]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[5] .. "��" .. WAR.Person[id]["��Ч����3"]
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

    --���ǵ�ϵ����
    if pid == 0 and JY.Base["��׼"] == 4 and 0 < JY.Person[pid]["�书9"] and 120 <= JY.Person[pid]["ˣ������"] and JLSD(25, 65 + pz, pid) and kfkind == 4 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[4]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[4] .. "��" .. WAR.Person[id]["��Ч����3"]
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
		--��������Լ���ŭ��25
		WAR.YZHYZ = WAR.YZHYZ + 25
    end

    --��������У��ڹ��ɴ���
    if pid == 0 and JY.Base["��׼"] == 6 and 0 < JY.Person[pid]["�书9"] and JLSD(25, 60 + pz, pid) and kfkind == 6 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[6]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[6] .. "��" .. WAR.Person[id]["��Ч����3"]
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

    --���Ƕ������У������ж�100�ɴ���
    if pid == 0 and JY.Base["��׼"] == 9 and 0 < JY.Person[pid]["�书9"] and JLSD(25, 60 + pz, pid) and JY.Person[pid]["�ж��̶�"] == 100 and JY.Person[pid]["�������"] > 0 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] == nil then
			WAR.Person[id]["��Ч����3"] = ZJTF[9]
		else
			WAR.Person[id]["��Ч����3"] = ZJTF[9] .. "��" .. WAR.Person[id]["��Ч����3"]
		end
		WAR.WS = 1
		JY.Person[pid]["�ж��̶�"] = 0
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

	--ŷ���ˣ���ŭʹ��ѩɽ�����ƣ���Ϊ����ȭ
	if match_ID(pid,61) and wugong == 9 and WAR.LQZ[pid] == 100 then
		WAR.OYK = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "������ȭ"
		else
			WAR.Person[id]["��Ч����1"] = "����ȭ"
		end
	end

	--��������������ʱ����󾢣����಻��
	if match_ID(pid, 55) and wugong == 26 and WAR.ACT > 1 then
		local txwz = {"һ", "��", "��", "��", "��", "��", "��", "��", "��", "ʮ", "ʮһ","ʮ��","ʮ��"}
		if inteam(pid) then
			WAR.YYBJ = math.random(0, JY.Base["��������"])
			if WAR.YYBJ > 13 then
				WAR.YYBJ = 13
			end
			--������������-7
			if JY.Base["��������"] > 7 then
				if WAR.YYBJ < JY.Base["��������"] - 7 then
					WAR.YYBJ = JY.Base["��������"] - 7
				end
			end
		else
			WAR.YYBJ = math.random(1, 10)
		end
		if WAR.YYBJ > 0 then
			ng = ng + WAR.YYBJ*150
			if WAR.Person[id]["��Ч����1"] ~= nil then
				WAR.Person[id]["��Ч����1"] = "���������಻����"..txwz[WAR.YYBJ].."�غ�".."+"..WAR.Person[id]["��Ч����1"]
			else
				WAR.Person[id]["��Ч����1"] = "���������಻����"..txwz[WAR.YYBJ].."�غ�"
			end
		end
	end

	--���࣬��Ԫ����
	if match_ID(pid, 604) and kfkind == 3 then
		WAR.TYJQ = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "����Ԫ����"
		else
			WAR.Person[id]["��Ч����1"] = "��Ԫ����"
		end
    end

	--�ֳ�Ӣ�������ѩ
	if match_ID(pid, 605) and JLSD(20, 80, pid) then
		WAR.LFHX = 1
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "�������ѩ"
		else
			WAR.Person[id]["��Ч����3"] = "�����ѩ"
		end
    end

	--��Ϧ���أ��򹷲��־�
	if wugong == 80 and match_ID(pid, 613) then
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+�򹷰��������־�"
		else
			WAR.Person[id]["��Ч����1"] = "�򹷰��������־�"
		end
	end

	--����̩ɽ��ʹ�ú�20ʱ��������
	if wugong == 31 and PersonKF(pid,175) then
		WAR.TSSB[pid] = 20
	end

	--�������޵��������ٵз��ƶ�
	if Curr_QG(pid,148) then
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+������"
		else
			WAR.Person[id]["��Ч����1"] = "������"
		end
	end

	--�޾Ʋ������ٻ���ԭ������+ȼľ+���浶����ŭ�����ȼЧ��
	if (wugong == 61 or wugong == 65 or wugong == 66) and JuHuoLY(pid) and WAR.LQZ[pid] == 100 then
		Set_Eff_Text(id,"��Ч����2","�ٻ���ԭ")
	end

	--�޾Ʋ��������к��棬����+����+���飬��ŭ��ɶ���Ч��
	if (wugong == 58 or wugong == 174 or wugong == 153) and LiRenHF(pid) and WAR.LQZ[pid] == 100 then
		Set_Eff_Text(id,"��Ч����2","���к���")
	end

	--����̫����̫��֮�أ�����ŭ
	if Curr_NG(pid, 102) and JLSD(20, 70 + JY.Base["��������"] + math.modf(JY.Person[pid]["ʵս"]/50), pid) then
		WAR.TXZZ = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "��̫��֮��"
		else
			WAR.Person[id]["��Ч����1"] = "̫��֮��"
		end
    end

	--һ����һ��ָ������ҵ��
	if match_ID(pid, 65) and wugong == 17 then
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = "����ҵ��"..WAR.Person[id]["��Ч����1"]
		else
			WAR.Person[id]["��Ч����1"] = "����ҵ��"
		end
	end

	--�ܲ�ͨ����֮���ʹ�з����Ụ�壬��ʼ����25%��ÿ20��ʵս+1%����
	if match_ID(pid, 64) and JLSD(20, 45 + math.modf(JY.Person[pid]["ʵս"]/20), pid) then
		WAR.KMZWD = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = "����֮�����"..WAR.Person[id]["��Ч����1"]
		else
			WAR.Person[id]["��Ч����1"] = "����֮���"
		end
    end

	--�Ž��洫��������������70%���ʴ���4����Ч֮һ
	--��Ϧ������Դ�
	if ((pid == 0 and JY.Person[592]["�۽�����"] == 1 and JLSD(15, 85,pid))
		or match_ID(pid, 610))
		and kfkind == 3 then
		local t = math.random(4)
		local wz = {"�뽣ʽ","����ʽ","�ý�ʽ","����ʽ"}
		WAR.JJZC = t
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .."+�Ž��洫��"..wz[t]
		else
			WAR.Person[id]["��Ч����1"] = "�Ž��洫��"..wz[t]
		end
	end

	--�����黭�������٣�����ŭ
	if wugong == 73 and QinqiSH(pid) then
		WAR.QQSH1 = 1
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "�������ö�"
		else
			WAR.Person[id]["��Ч����1"] = "�����ö�"
		end
		--50%���ʴ�����ŭ
		if JLSD(20, 70, pid) then
			WAR.QQSH1 = 2
			if WAR.Person[id]["��Ч����1"] ~= nil then
				WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "����������"
			else
				WAR.Person[id]["��Ч����1"] = "��������"
			end
		end
    end

	--�����黭����ʵ��࣬����
	if wugong == 142 and QinqiSH(pid) then
		--60%���ʱ���
		if JLSD(20, 80, pid) then
			WAR.QQSH2 = 1
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "������Ϊ��"
			else
				WAR.Person[id]["��Ч����3"] = "����Ϊ��"
			end
		end

		--30%���ʴ����
		if JLSD(30, 60, pid) then
			WAR.QQSH2 = 2
			if WAR.Person[id]["��Ч����3"] ~= nil then
				WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "����ɽ�续"
			else
				WAR.Person[id]["��Ч����3"] = "��ɽ�续"
			end
		end
	end

	--�����黭��������������50%���ʳ���Ч���˺����20%���ط�Ѩ
	if wugong == 84 and QinqiSH(pid) and JLSD(20, 70, pid) then
		WAR.QQSH3 = 1
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "������ֱ��"
		else
			WAR.Person[id]["��Ч����3"] = "����ֱ��"
		end
	end

	--������Ů��ز�ÿձ̣������˺�ɱ������
	if Curr_NG(pid, 154) and WAR.ACT > 1 and JLSD(30, 60 + JY.Base["��������"]*2, pid) then
		WAR.YNXJ = 1
		if WAR.Person[id]["��Ч����0"] ~= nil then
			WAR.Person[id]["��Ч����0"] = WAR.Person[id]["��Ч����0"] .. "+ز�ÿձ�"
		else
			WAR.Person[id]["��Ч����0"] = "ز�ÿձ�"
		end
    end

    --ŭ������

	if IsAlone(id) then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+��עһ��"
		else
			WAR.Person[id]["��Ч����3"] = "��עһ��"
		end
    end

	if GetWarMap(WAR.Person[id]["����X"], WAR.Person[id]["����Y"], 6) == 2 then
		WAR.Person[id]["��Ч����"] = 6
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = WAR.Person[id]["��Ч����3"] .. "+������λ"
		else
			WAR.Person[id]["��Ч����3"] = "������λ"
		end
	end --��ɫ

	--ȫ�����ӣ��������������ʾ
	if WAR.ZDDH == 73 then
		if (pid >= 123 and pid <= 128) or pid == 68 then
			WAR.Person[id]["��Ч����"] = 93
			if WAR.Person[id]["��Ч����2"] ~= nil then
				WAR.Person[id]["��Ч����2"] = WAR.Person[id]["��Ч����2"] .. "+����������"
			else
				WAR.Person[id]["��Ч����2"] = "����������"
			end
		end
	end

    --��������
    if WAR.Actup[pid] ~= nil then
    	--����������󡣬׷��ɱ��
		if Curr_NG(pid, 103) or Curr_NG(pid, 95) then
			ng = ng + 1200
		else
			ng = ng + 600
		end
		local str = "��������"
		if WAR.SLSX[pid] ~= nil then
			str = str .. "��ʮ��ʮ��"
		end
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = WAR.Person[id]["��Ч����1"] .. "+"..str
		else
			WAR.Person[id]["��Ч����1"] = str
		end
    end

    --�����񹦼���ʱ��ʹ�þ����׹�צ��������צ
	if wugong == 11 and WAR.NGJL == 107 then
		ng = ng + 2000
		WAR.WS = 1
		if WAR.Person[id]["��Ч����3"] ~= nil then
			WAR.Person[id]["��Ч����3"] = "������צ��"..WAR.Person[id]["��Ч����3"]
		else
			WAR.Person[id]["��Ч����3"] = "������צ"
		end
	end

    --��Ч����1������Ϊ��ɫȦ
    if WAR.Person[id]["��Ч����1"] ~= nil and WAR.Person[id]["��Ч����"] == -1 then
		WAR.Person[id]["��Ч����"] = 88
    end

	--������������Ч����
	if match_ID(pid, 129) and WAR.CYZX[pid] ~= nil and WAR.BDQS > 0 then
		WAR.Person[id]["��Ч����"] = 126
	end

	--�޾Ʋ�������Ч����
	if pid == 0 and JY.Base["����"] == 1 then
		WAR.Person[id]["��Ч����"] = 132
	end

	--���˷��ƾ��Ķ���������
	if match_ID(pid, 3) and WAR.MRF == 1 then
		if WAR.Person[id]["��Ч����1"] ~= nil then
			WAR.Person[id]["��Ч����1"] = "�ƾ���"..WAR.Person[id]["��Ч����1"]
		else
			WAR.Person[id]["��Ч����1"] = "�ƾ�"
		end
		WAR.Person[id]["��Ч����"] = 146
	end

    --�޾Ʋ�����������ܵ����ַ���
	if WAR.ACT == 1 then
		local hit_DGQB;
		for i = 0, CC.WarWidth - 1 do
			for j = 0, CC.WarHeight - 1 do
				local effect = GetWarMap(i, j, 4)
				if 0 < effect then
					local emeny = GetWarMap(i, j, 2)
					if emeny >= 0 and emeny ~= WAR.CurID then
						if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] and match_ID(WAR.Person[emeny]["������"], 592) then
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
			local tx_1 = WAR.Person[id]["��Ч����0"] or nil
			local tx_2 = WAR.Person[id]["��Ч����1"] or nil
			local tx_3 = WAR.Person[id]["��Ч����2"] or nil
			local tx_4 = WAR.Person[id]["��Ч����3"] or nil
			local tx_5 = WAR.Person[id]["��Ч����4"] or nil
			local tx_6 = WAR.Person[id]["��Ч����"]
			WAR.Person[id]["��Ч����0"] = nil
			WAR.Person[id]["��Ч����1"] = nil
			WAR.Person[id]["��Ч����2"] = nil
			WAR.Person[id]["��Ч����3"] = nil
			WAR.Person[id]["��Ч����4"] = nil
			WAR.Person[id]["��Ч����"] = -1
			WAR.hit_DGQB = 1
			WAR.Person[hit_DGQB]["��Ч����"] = 83
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
				if WAR.Person[i]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[i]["����"] == false then
					local pid = WAR.Person[WAR.CurID]["������"]
					local eid = WAR.Person[i]["������"]
					local dam;
					dam = First_strike_dam_DG(pid, eid)
					if dam > 0 then
						WAR.Person[i]["��������"] = (WAR.Person[i]["��������"] or 0) - dam
						--�޾Ʋ�������¼����Ѫ��
						WAR.Person[i]["Life_Before_Hit"] = JY.Person[eid]["����"]
						JY.Person[eid]["����"] = JY.Person[eid]["����"] - dam
						if JY.Person[eid]["����"] < 0 then
							JY.Person[eid]["����"] = 0
						end
						SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 4, 2)
					end
				end
			end
			War_ShowFight(WAR.Person[hit_DGQB]["������"], 0, 0, 0, 0, 0, 60, -1)
			WAR.hit_DGQB = 0
			WAR.Person[hit_DGQB]["��Ч����"] = -1

			--�������һ��������������ô������Ĺ����ͽ�����
			if JY.Person[WAR.Person[s1]["������"]]["����"] <= 0 then
				return 1
			else
				WAR.CurID = s1
				CleanWarMap(4, 0)
				WAR.Effect = 0
				for i = 1, pre_target_num do
					SetWarMap(pre_target_list[i][1], pre_target_list[i][2], 2, pre_target_list[i][3])
					SetWarMap(pre_target_list[i][1], pre_target_list[i][2], 4, pre_target_list[i][4])
				end
				WAR.Person[id]["��Ч����0"] = tx_1
				WAR.Person[id]["��Ч����1"] = tx_2
				WAR.Person[id]["��Ч����2"] = tx_3
				WAR.Person[id]["��Ч����3"] = tx_4
				WAR.Person[id]["��Ч����4"] = tx_5
				WAR.Person[id]["��Ч����"] =  tx_6
			end
		end
	end

	--����ˮ����ת��û�д����������߷����������ſɴ�������30%���ʴ���
	if (WAR.WXFS == nil or (WAR.WXFS ~= nil and WAR.Person[WAR.WXFS]["����"] == true)) and math.random(10) < 4 then
		local lqs_WXZS;
		for i = 0, CC.WarWidth - 1 do
			for j = 0, CC.WarHeight - 1 do
				local effect = GetWarMap(i, j, 4)
				if 0 < effect then
					local emeny = GetWarMap(i, j, 2)
					if emeny >= 0 and emeny ~= WAR.CurID then
						--���޳������Ǵ���
						if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] and match_ID(WAR.Person[emeny]["������"], 118) and WAR.Person[emeny]["������"] == 0 then
							lqs_WXZS = emeny
							SetWarMap(i, j, 4, 0)
							break;
						end
					end
				end
			end
		end

		if lqs_WXZS ~= nil then

			--ID��ʱ��������ˮ
			local s = WAR.CurID
			WAR.CurID = lqs_WXZS
			local wxlox, wxloy;
			War_CalMoveStep(WAR.CurID, 10, 0)
			local function SelfXY(x, y)
				local yes = 0
				if x == WAR.Person[WAR.CurID]["����X"] then
					yes = yes +1
				end
				if y == WAR.Person[WAR.CurID]["����Y"] then
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
				--ESC�˳�
				else
					WAR.ShowHead = 0
					x, y = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
					--wxlox, wxloy = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
					break;
				end
			end
			--��������λ�ò��ܴ�������
			if SelfXY(x, y) == false then
				SetWarMap(wxlox, wxloy, 4, 0)
				--������û����������ת�������������
				if WAR.WXFS == nil then
					WAR.Person[WAR.PersonNum]["������"] = 600
					WAR.Person[WAR.PersonNum]["�ҷ�"] = WAR.Person[WAR.CurID]["�ҷ�"]
					WAR.Person[WAR.PersonNum]["����X"] = wxlox
					WAR.Person[WAR.PersonNum]["����Y"] = wxloy
					WAR.Person[WAR.PersonNum]["����"] = false
					WAR.Person[WAR.PersonNum]["�˷���"] = WAR.Person[WAR.CurID]["�˷���"]
					WAR.Person[WAR.PersonNum]["��ͼ"] = WarCalPersonPic(WAR.PersonNum)
					lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[600]["ͷ�����"]), string.format(CC.FightPicFile[2], JY.Person[600]["ͷ�����"]), 4 + WAR.PersonNum)
					WAR.tmp[5000+WAR.PersonNum] = JY.Person[600]["ͷ�����"]
					WAR.JQSDXS[600] = 0	--ֱ��ָ�������������ٻ��������ϱ���ת����
					WAR.WXFS = WAR.PersonNum
					WAR.PersonNum = WAR.PersonNum + 1
				--�Ѿ������������÷�����
				else
					WAR.Person[WAR.WXFS]["����"] = false
					WAR.Person[WAR.WXFS]["�ҷ�"] = WAR.Person[WAR.CurID]["�ҷ�"]
					WAR.Person[WAR.WXFS]["����X"] = wxlox
					WAR.Person[WAR.WXFS]["����Y"] = wxloy
					WAR.Person[WAR.WXFS]["�˷���"] = WAR.Person[WAR.CurID]["�˷���"]
					WAR.Person[WAR.WXFS]["��ͼ"] = WarCalPersonPic(WAR.WXFS)
					JY.Person[600]["����"] = JY.Person[600]["�������ֵ"]
					JY.Person[600]["����"] = JY.Person[600]["�������ֵ"]
					JY.Person[600]["����"] = 100
					JY.Person[600]["���˳̶�"] = 0
					JY.Person[600]["�ж��̶�"] = 0
					JY.Person[600]["����̶�"] = 0
					JY.Person[600]["���ճ̶�"] = 0
					WAR.Person[WAR.WXFS].Time = 0
					--��Ѫ
					if WAR.LXZT[600] ~= nil then
						WAR.LXZT[600] = nil
					end
					--��Ѩ
					if WAR.FXDS[600] ~= nil then
						WAR.FXDS[600] = nil
					end
				end

				--�������λ����ͼ
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)

				--�޸��������������
				WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], WAR.Person[WAR.WXFS]["����X"], WAR.Person[WAR.WXFS]["����Y"] = WAR.Person[WAR.WXFS]["����X"], WAR.Person[WAR.WXFS]["����Y"],WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]

				--���ӻ�����ͼ
				SetWarMap(WAR.Person[WAR.WXFS]["����X"], WAR.Person[WAR.WXFS]["����Y"], 5, WAR.Person[WAR.WXFS]["��ͼ"])
				SetWarMap(WAR.Person[WAR.WXFS]["����X"], WAR.Person[WAR.WXFS]["����Y"], 2, WAR.WXFS)

				--����������ͼ
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
			end
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 90,1,"����ת��")

			--��ԭID���������
			WAR.CurID = s
			WAR.ACT = 10
		end
	end

    --�����˺��ĵ���
    for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			lib.GetKey()
			local effect = GetWarMap(i, j, 4)
			if 0 < effect then
				local emeny = GetWarMap(i, j, 2)
				if 0 <= emeny and emeny ~= WAR.CurID then		--������ˣ����Ҳ��ǵ�ǰ������
					--������תǬ��������£���������Ч�ͺϻ���Ȼ����Լ���
					if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] or (ZHEN_ID < 0 and WAR.WS == 0) or WAR.NZQK > 0 then
						if JY.Wugong[wugong]["�˺�����"] == 1 and (fightscope == 0 or fightscope == 3) then
							if level == 11 then
								level = 10
							end
							--�޾Ʋ�����������Ҫ�����޸�
							--WAR.Person[emeny]["��������"] = (WAR.Person[emeny]["��������"] or 0) - War_WugongHurtNeili(emeny, wugong, level)
							SetWarMap(i, j, 4, 3)
							WAR.Effect = 3
						else
							--�ֳ�Ӣ���Ʊ��£�ÿ50ʱ��ɴ���һ�Σ������˺�10ʱ�����˲�����
							if match_ID(WAR.Person[emeny]["������"], 605) and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
								if WAR.QYBY[WAR.Person[emeny]["������"]] == nil then
									WAR.QYBY[WAR.Person[emeny]["������"]] = 50
								end
								if WAR.QYBY[WAR.Person[emeny]["������"]] > 40 then
									WAR.Person[emeny]["��Ч����3"] = "���Ʊ���"
									WAR.Person[emeny]["��Ч����"] = 102
								else
									WAR.Person[emeny]["��������"] = (WAR.Person[emeny]["��������"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(i, j, 4, 2)
								end
							--���Ǿ��Ѻ����㿪��ǰ���β����˺�
							elseif match_ID(WAR.Person[emeny]["������"], 92) and JY.Person[0]["�������"] > 0 and WAR.FF < 3 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
								WAR.FF = WAR.FF + 1
								WAR.Person[emeny]["��Ч����"] = 135
							--���˿���
							elseif WAR.QGZT[WAR.Person[emeny]["������"]] ~= nil and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
								local list = {}
								for q = 0, WAR.PersonNum - 1 do
									if WAR.Person[q]["����"] == false and q ~= WAR.CurID and WAR.Person[q]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
										table.insert(list,q)
									end
								end
								local F_target
								if list[1] ~= nil then
									WAR.Person[emeny]["��Ч����"] = 149
									F_target = list[math.random(#list)]
									WAR.NZQK = 3
									WAR.Person[F_target]["��������"] = (WAR.Person[F_target]["��������"] or 0) - War_WugongHurtLife(F_target, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(WAR.Person[F_target]["����X"], WAR.Person[F_target]["����Y"], 4, 2)
									WAR.NZQK = 0
								else
									WAR.Person[emeny]["��������"] = (WAR.Person[emeny]["��������"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
									WAR.Effect = 2
									SetWarMap(i, j, 4, 2)
								end
								--�����Ƿ��е��������������Ƿ񷴵���������һ�δ���
								WAR.QGZT[WAR.Person[emeny]["������"]] = WAR.QGZT[WAR.Person[emeny]["������"]] -1
								if WAR.QGZT[WAR.Person[emeny]["������"]] < 1 then
									WAR.QGZT[WAR.Person[emeny]["������"]] = nil
								end
							else
								WAR.Person[emeny]["��������"] = (WAR.Person[emeny]["��������"] or 0) - War_WugongHurtLife(emeny, wugong, level, ng, x, y)
								WAR.Effect = 2
								SetWarMap(i, j, 4, 2)
							end
							--��˯״̬�ĵ��˻�����
							if WAR.CSZT[WAR.Person[emeny]["������"]] ~= nil then
								WAR.CSZT[WAR.Person[emeny]["������"]] = nil
							end
						end
					end
				end
			end
		end
    end

	--�޾Ʋ����������Ĵ�����Ч
    local dhxg = JY.Wugong[wugong]["�书����&��Ч"]
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

	--���Ƴ�������׷������
	if WAR.CXLC == 1 and WAR.CXLC_Count < 3 then
		fightnum = fightnum + 1
		WAR.CXLC_Count = WAR.CXLC_Count + 1
	end

	--Ѫ����Ѫ������100��
	if WAR.XDLeech > 0 then
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", WAR.XDLeech);
	end

	--ΤһЦ��Ѫ10%������100��
	if WAR.WYXLeech > 0 then
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", WAR.WYXLeech);
	end

	--��ħ����Ѫ20%
	if WAR.TMGLeech > 0 then
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", WAR.TMGLeech);
	end

	--Ѫ�������Ѫ������100��
	if WAR.XHSJ > 0 then
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", WAR.XHSJ);
	end

	--�޾Ʋ���������Ĺ��������͵�����ʾ
	War_ShowFight(pid, wugong, JY.Wugong[wugong]["�书����"], level, x, y, dhxg, ZHEN_ID)

	--����ҵ��״̬������ʹ�õ�����һ�������
	if WAR.WMYH[pid] ~= nil then
		CurIDTXDH(WAR.CurID, 127,1, "����ҵ��", C_ORANGE)
		local nlDam = math.modf((math.modf((level + 3) / 2) * JY.Wugong[wugong]["������������"])/2)
		WAR.Person[WAR.CurID]["��������"] = (WAR.Person[WAR.CurID]["��������"] or 0) + AddPersonAttrib(pid, "����", -nlDam)
	    --������1��Ѫ
	    if JY.Person[pid]["����"] <= 0 then
			JY.Person[pid]["����"] = 1
	    end
	end

	War_Show_Count(WAR.CurID);		--��ʾ��ǰ�����˵ĵ���

	WAR.TFBW = 0		--�����λ�����ּ�¼�ָ�
	WAR.TLDWX = 0		--���޵��������ּ�¼�ָ�

    WAR.Person[WAR.CurID]["����"] = WAR.Person[WAR.CurID]["����"] + 2

    --[[�ҷ������ĵ�����
    if WAR.Person[WAR.CurID]["�ҷ�"] then
		local nl = nil

		nl = math.modf((level + 3) / 2) * JY.Wugong[wugong]["������������"]

		--����������������
		--����
		if Curr_NG(pid, 99) then
			nl = math.modf(nl*0.4);
		--����
		elseif PersonKF(pid, 99) then
			nl = math.modf(nl*0.5);
		end

		--�������˾���������70%����
		if Curr_NG(pid, 106) and (JY.Person[pid]["��������"] == 1 or (pid == 0 and JY.Base["��׼"] == 6)) then
			nl = math.modf(nl*0.3);
		end

		--�Ƿ彵�����ļ���
		if match_ID(pid, 50) and wugong == 26 then
			nl = math.modf(nl/2);
		end

		--�����������ļ���
		if match_ID(pid, 53) and wugong == 49 then
			nl = math.modf(nl/2);
		end

		--ָ�������������ļ���
		if pid == 0 and JY.Base["��׼"] == 2 and wugong == 49 then
			nl = math.modf(nl/2);
		end

		--���⹥����ֻ����һ������
		if Given_WG(pid, wugong) then
			nl = math.modf(nl/2);
		end

		AddPersonAttrib(pid, "����", -(nl))
	--NPC�ĺ���
	else
		AddPersonAttrib(pid, "����", -math.modf((level + 3) / 2) * JY.Wugong[wugong]["������������"]/7*2)
    end]]

    if JY.Person[pid]["����"] < 0 then
		JY.Person[pid]["����"] = 0
    end

    if JY.Person[pid]["����"] <= 0 then
		break;
    end


	--�޾Ʋ�������ɱ���Ķ�̬��ʾ
  	DrawTimeBar2()

	--̫��ȭ�������������������
	--�����᲻���
	if wugong == 16 and WAR.tmp[3000 + pid] ~= nil and WAR.tmp[3000 + pid] > 0 and match_ID(pid, 5) == false then
		WAR.tmp[3000 + pid] = 0
	end

	WAR.ACT = WAR.ACT + 1   --ͳ�ƹ��������ۼ�1

  	--�����壺������Χ�ڵĵ���ȫ������ʱȡ������
  	local flag = 0;
  	local n = 0;
    for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			lib.GetKey()
			local effect = GetWarMap(i, j, 4)
			if 0 < effect then
				local emeny = GetWarMap(i, j, 2)
				if 0 <= emeny and WAR.Person[id]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
					n = n + 1;
					if JY.Person[WAR.Person[emeny]["������"]]["����"] > 0 then
						flag = 1;
					end
				end
    		end
    	end
    end

	--�޾Ʋ����������ز����ж�����
    if flag == 0 and n > 0 and match_ID(pid, 2) == false then
    	break;
    end

	--����̫���񹦣�̫��֮����������
	if Curr_NG(pid, 171) and WAR.TJZX[pid] ~= nil and WAR.TJZX[pid] >= 5 then
		fightnum = fightnum + 1
		WAR.TJZX[pid] = WAR.TJZX[pid] - 5
		WAR.TJZX_LJ = 1
	end

  end

	--��������
	if JY.Restart == 1 then
		return 1
	end

	--���������ж�ȡ��
	WAR.TWLJ = 0

	--��Ȼ���ⷶΧ�ָ�
	WAR.ARJY = 0

	--���Ƴ������Ǽ����ָ�
	WAR.CXLC_Count = 0

	--̫��ȭ�������������������
	--���������������
	if wugong == 16 and WAR.tmp[3000 + pid] ~= nil and WAR.tmp[3000 + pid] > 0 and match_ID(pid, 5) then
		WAR.tmp[3000 + pid] = 0
	end

	--�����������תǬ����ǿ������Ч����������ָ�
	if WAR.NZQK > 0 then
		WAR.NZQK = 0
	end

	--�������ĵ�����
	local jtl = 1

	--������������
	AddPersonAttrib(pid, "����", -jtl);

	--��ת���Ƽ��㣬���������ܷ�������ʱ��������
	if WAR.Person[WAR.CurID]["�����书"] ~= 9999 then
	local dz = {}
	local dznum = 0
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["�����书"] ~= -1 and WAR.Person[i]["�����书"] ~= 9999 then
			dznum = dznum + 1
			dz[dznum] = {i, WAR.Person[WAR.CurID]["����X"] - WAR.Person[i]["����X"], WAR.Person[WAR.CurID]["����Y"] - WAR.Person[i]["����Y"]}
			WAR.Person[i]["�����书"] = 9999
		end
	end
	for i = 1, dznum do
		local rid = WAR.Person[dz[i][1]]["������"]
		local kongfuid = JY.Person[rid]["�����ڹ�"]
		
		local datas = GetValidTargets(dz[i][1], kongfuid)
		--JY.Person[rid]["����"] = dz[i][2].."��ͷ"..dz[i][3]
		local data = {}
		data.x, data.y = dz[i][2], dz[i][3]
		if Contains(datas, data) then
			local tmp = WAR.CurID
			WAR.CurID = dz[i][1]
			WAR.DZXY = 1

			War_Fight_Sub(dz[i][1], kongfuid + 100, WAR.Person[tmp]["����X"], WAR.Person[tmp]["����Y"])
			
			WAR.CurID = tmp
			WAR.DZXY = 0
		end
		WAR.Person[dz[i][1]]["�����书"] = -1
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
	local pid = WAR.Person[warid]["������"]
	if xx == nil then
		xx = 0
	end
	if yy == nil then
		yy = 0
	end
	--xx = xx + WAR.Person[warid]["����X"]
	--yy = yy + WAR.Person[warid]["����Y"]
	local targets2 = {}
	local targets2index = 0
	for i = 1, #targets do
		local mid = GetWarMap(targets[i].x + xx, targets[i].y + yy, 2)
		if mid ~= nil and mid >= 0 and WAR.Person[warid]["�ҷ�"] ~= WAR.Person[mid]["�ҷ�"] then
			targets2index = targets2index + 1
			targets2[targets2index] = {}
			targets2[targets2index].x = targets[i].x
			targets2[targets2index].y = targets[i].y
		end
	end
	return targets2
end

function GetValidTargets(warid, kungfuid)
	local pid = WAR.Person[warid]["������"]
	if kungfuid == nil then
		kungfuid = JY.Person[pid]["�����ڹ�"]
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

--�޾Ʋ�����ѡ���ƶ�
--����7*7����ʾflag
function War_SelectMove(flag)
	local x0 = WAR.Person[WAR.CurID]["����X"]
	local y0 = WAR.Person[WAR.CurID]["����Y"]
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

		--����ʱ��ʾ������
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

		--�޾Ʋ�������������
		if GetWarMap(x2, y2, 3) ~= nil and GetWarMap(x2, y2, 3) < 128 then
			x = x2
			y = y2
		end
	end
end

--��ȡ�书��С����
function War_GetMinNeiLi(pid)
	local minv = math.huge
	for i = 1, CC.Kungfunum do
		local tmpid = JY.Person[pid]["�书" .. i]
		if tmpid > 0 and JY.Wugong[tmpid]["������������"] < minv then
			minv = JY.Wugong[tmpid]["������������"]
		end
	end
	return minv
end

--�޾Ʋ������ֶ�ս���˵��ϼ�
function War_Manual()
	local r = nil
	local x, y, move, pic, face_dir = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], WAR.Person[WAR.CurID]["�ƶ�����"], WAR.Person[WAR.CurID]["��ͼ"], WAR.Person[WAR.CurID]["�˷���"]
	while true do
		if JY.Restart == 1 then
			break
		end
		WAR.ShowHead = 1
		r = War_Manual_Sub()
		--�ƶ�������ʵ�ʷ��ص�Ӧ����-1
		if r == 1 or r == -1 then
			--WAR.Person[WAR.CurID]["�ƶ�����"] = 0 
		--ESC����
		elseif r == 0 then
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
			WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], WAR.Person[WAR.CurID]["�ƶ�����"] = x, y, move
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, pic)
			--�޾Ʋ�������������ҲҪ��ԭ
			WAR.Person[WAR.CurID]["�˷���"] = face_dir
		elseif r == 20 then

		else
			break;
		end
	end
	WAR.ShowHead = 0
	WarDrawMap(0)
	return r	--�޾Ʋ���������ķ���ֵ�ƺ�ûʲô����
end

--�ֶ�ս���˵�
function War_Manual_Sub()
	local pid = WAR.Person[WAR.CurID]["������"]
	--local isEsc = 0
	local warmenu = {
	{"�ƶ�", War_MoveMenu, 1},	--1
	{"����", War_FightMenu, 1},	--2
	{"�˹�", War_YunGongMenu, 1},	--3
	{"ս��", War_TacticsMenu, 1},	--4
	{"�ö�", War_PoisonMenu, 1},	--5
	{"�ⶾ", War_DecPoisonMenu, 1},	--6
	{"ҽ��", War_DoctorMenu, 1},	--7
	{"��Ʒ", War_ThingMenu, 1},	--8
	{"״̬", War_StatusMenu, 1},	--9
	{"��Ϣ", War_RestMenu, 1},	--10
	{"��ɫ", War_TgrtsMenu, 1},	--11
	{"����", War_Retreat, 1},	--12
	{"�Զ�", War_AutoMenu, 1}	--13
	}

	--��ɫָ��
	if JY.Person[pid]["��ɫָ��"] == 1 then
		--����ǳ���
		if pid == 0 then
			warmenu[11][1] = GRTS[JY.Base["����"]]
		else
			warmenu[11][1] = GRTS[pid]
		end
	else
		warmenu[11][3] = 0
	end

	--����
	if match_ID(pid, 49) then
		--���û��������������������ʾ��ɫָ��
		local t = 0
		for i = 0, WAR.PersonNum - 1 do
			local wid = WAR.Person[i]["������"]
			if WAR.TZ_XZ_SSH[wid] == 1 and WAR.Person[i]["����"] == false then
				t = 1
			end
		end
		if t == 0 then
			warmenu[11][3] = 0
		end
		--����С��20����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--��ǧ��
	if match_ID(pid, 88) then
		--�����Χû�ж��Ѳ���ʾ��ɫָ��
		local yes = 0
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["�ҷ�"] == true and WAR.Person[i]["����"] == false and RealJL(WAR.CurID, i, 5) and i ~= WAR.CurID then
				yes = 1
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--����С��20����ʾ��ɫָ��
		--����С��1000����ʾ
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--�˳���
	if match_ID(pid, 89) then
		--�����Χû�ж��Ѳ���ʾ��ɫָ��
		local px, py = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
		local mxy = {
					{WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] + 1},
					{WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] - 1},
					{WAR.Person[WAR.CurID]["����X"] + 1, WAR.Person[WAR.CurID]["����Y"]},
					{WAR.Person[WAR.CurID]["����X"] - 1, WAR.Person[WAR.CurID]["����Y"]}}

		local yes = 0
		for i = 1, 4 do
			if GetWarMap(mxy[i][1], mxy[i][2], 2) >= 0 then
			local mid = GetWarMap(mxy[i][1], mxy[i][2], 2)
			if inteam(WAR.Person[mid]["������"]) then
				yes = 1
				end
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--����С��25����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 25 then
			warmenu[11][3] = 0
		end
	end

	--���޼�
	if match_ID(pid, 9) then
		--�����Χû�ж��Ѳ���ʾ��ɫָ��
		local yes = 0
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["�ҷ�"] == true and WAR.Person[i]["����"] == false and RealJL(WAR.CurID, i, 8) and i ~= WAR.CurID then
				yes = 1
			end
		end
		if yes == 0 then
			warmenu[11][3] = 0
		end
		--����С��20����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--�����壺����ͩͳ��ָ��
	if match_ID(pid, 74) then
		--����С��10����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 10 or JY.Person[pid]["����"] < 150 then
			warmenu[11][3] = 0
		end
	end

	--Ľ�ݸ�ָ�� ����
	if match_ID(pid, 51) then
		--����С��20����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--С��ָ�� Ӱ��
	if match_ID(pid, 66) then
		--����С��30��������С��2000����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 30 or JY.Person[pid]["����"] < 2000 then
			warmenu[11][3] = 0
		end
	end

	--����ָ�� ����
	if match_ID(pid, 90) then
		--����С��10����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 10 then
			warmenu[11][3] = 0
		end
	end

	--����ָ�� ��װ
	if match_ID(pid, 92) then
		--����С��20����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--���ָ�� �ɺ�
	if match_ID(pid, 1) then
		--����С��20����ʾ��ɫָ��
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--�Ħ��ָ�� �û�
	if match_ID(pid, 103) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--�����ָ�� ��ս
	if match_ID(pid, 160) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 or WAR.SZSD ~= -1 then
			warmenu[11][3] = 0
		end
	end

	--���� ����
	if match_ID(pid, 62) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--���� �ݼ�
	if match_ID(pid, 56) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--ΤС�� �ڲ�
	if match_ID(pid, 601) then
		if JY.Person[pid]["����"] < 30 then
			warmenu[11][3] = 0
		end
	end

	--���˷� �ƾ�
	if match_ID(pid, 3) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--��̫�� ����
	if match_ID(pid, 7) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--��֤ ����
	if match_ID(pid, 149) then
		if JY.Person[pid]["����"] < 20 or JY.Person[pid]["����"] < 1000 then
			warmenu[11][3] = 0
		end
	end

	--�ֻ� ����
	if match_ID(pid, 4) then
		if JY.Person[pid]["����"] < 20 then
			warmenu[11][3] = 0
		end
	end

	--������ʱ���ƶ����ⶾ��ҽ�ƣ���Ʒ����ɫ���Զ����ɼ�
	if WAR.ZYHB == 2 then
		warmenu[1][3] = 0
		warmenu[6][3] = 0
		warmenu[7][3] = 0
		warmenu[8][3] = 0
		warmenu[11][3] = 0
		warmenu[13][3] = 0
	end

	--����С��5�����Ѿ��ƶ���ʱ���ƶ����ɼ�
	if JY.Person[pid]["����"] <= 5 or WAR.Person[WAR.CurID]["�ƶ�����"] <= 0 then
		warmenu[1][3] = 0
		--isEsc = 1
	end

	--�ж���С�������Ƿ����ʾ����
	local minv = War_GetMinNeiLi(pid)
	if JY.Person[pid]["����"] < minv or JY.Person[pid]["����"] < 10 then
		warmenu[2][3] = 0
	end

	--�ö��ⶾҽ�ƣ�567
	if JY.Person[pid]["����"] < 10 or JY.Person[pid]["�ö�����"] < 20 then
		warmenu[5][3] = 0
	end
	if JY.Person[pid]["����"] < 10 or JY.Person[pid]["�ⶾ����"] < 20 then
		warmenu[6][3] = 0
	end
	if JY.Person[pid]["����"] < 50 or JY.Person[pid]["ҽ������"] < 20 then
		warmenu[7][3] = 0
	end

	lib.GetKey()
	Cls()
	DrawTimeBar_sub()
	return ShowMenu(warmenu, #warmenu, 0, CC.MainMenuX, CC.MainMenuY, 0, 0, 1, 1, CC.DefaultFont, C_ORANGE, C_WHITE)
end

--�޾Ʋ������˹�ѡ��˵�
function War_YunGongMenu()
	local id = WAR.Person[WAR.CurID]["������"]
	local menu={};
	menu[1]={"�����ڹ�",SelectNeiGongMenu,1};
	menu[2]={"ͣ���ڹ�",nil,1};
	menu[3]={"�����Ṧ",SelectQingGongMenu,1};
	menu[4]={"ͣ���Ṧ",nil,1};
    local r = ShowMenu(menu,#menu,0,CC.MainSubMenuX+15,CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if r == 2 then
		JY.Person[id]["�����ڹ�"] = 0
		DrawStrBoxWaitKey(JY.Person[id]["����"].."ֹͣ���������ڹ�",C_RED,CC.DefaultFont,nil,LimeGreen)
		return 20;
	elseif r == 20 then
		return 20;
	elseif r == 4 then
		JY.Person[id]["�����Ṧ"] = 0
		DrawStrBoxWaitKey(JY.Person[id]["����"].."ֹͣ���������Ṧ",M_DeepSkyBlue,CC.DefaultFont,nil,LimeGreen)
		return 20;
	elseif r == 10 then
		return 10;
	end
end

--�޾Ʋ�����ѡ���ڹ��˵�
function SelectNeiGongMenu()
	local id, x1, y1 = WAR.Person[WAR.CurID]["������"], WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
	local menu={};
	for i=1,CC.Kungfunum do
        menu[i]={JY.Wugong[JY.Person[id]["�书" .. i]]["����"],nil,0};
		if JY.Wugong[JY.Person[id]["�书" .. i]]["�书����"] == 6 then
			menu[i][3]=1;
		end
		--�����������
		if id == 0 and JY.Base["��׼"] == 6 and (JY.Person[id]["�书" .. i] == 106 or JY.Person[id]["�书" .. i] == 107 or JY.Person[id]["�书" .. i] == 108) then
			menu[i][3]=0;
		end
		--��������������
		if JY.Person[id]["�书" .. i] == 175 then
			menu[i][3]=0
		end
	end
    local main_neigong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if main_neigong ~= nil and main_neigong > 0 then
		CleanWarMap(4, 0)
		SetWarMap(x1, y1, 4, 1)
		War_ShowFight(id, 0, 0, 0, 0, 0, 9)
		AddPersonAttrib(id, "����", -200);
		AddPersonAttrib(id, "����", -5);
		JY.Person[id]["�����ڹ�"] = JY.Person[id]["�书" .. main_neigong]
		return 20;
	end
end

--�޾Ʋ�����ѡ���Ṧ�˵�
function SelectQingGongMenu()
	local id, x1, y1 = WAR.Person[WAR.CurID]["������"], WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
	local menu={};
	for i=1,CC.Kungfunum do
        menu[i]={JY.Wugong[JY.Person[id]["�书" .. i]]["����"],nil,0};
		if JY.Wugong[JY.Person[id]["�书" .. i]]["�书����"] == 7 then
			menu[i][3]=1;
		end
	end
    local main_qinggong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	if main_qinggong ~= nil and main_qinggong > 0 then
		CleanWarMap(4, 0)
		SetWarMap(x1, y1, 4, 1)
		War_ShowFight(id, 0, 0, 0, 0, 0, 9)
		AddPersonAttrib(id, "����", -10);
		WAR.YQG = 1
		JY.Person[id]["�����Ṧ"] = JY.Person[id]["�书" .. main_qinggong]
		return 10;
	end
end

--�޾Ʋ�����ս���˵�
function War_TacticsMenu()
	local menu={};
	menu[1]={"����",nil,1};
	menu[2]={"����",nil,1};
	menu[3]={"�ȴ�",nil,1};
    local r = ShowMenu(menu,#menu,0,CC.MainSubMenuX+15,CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
	--����
	if r == 1 then
		return War_ActupMenu()
	--����
	elseif r == 2 then
		return War_DefupMenu()
	--�ȴ�
	elseif r == 3 then
		return War_Wait()
	--��ݼ��Ķ����ж�
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
		if WAR.Person[j]["����"] == false and targetTime < WAR.Person[j].Time and WAR.Person[j].Time < ownTime then
			target = j
			targetTime = WAR.Person[j].Time
		end
	end
	if target == -1 then
		--�Ѿ��ǵ�����һ
		return
	end
	--lib.Debug(WAR.Person[target]["������"])
	WAR.Person[warid].Time, WAR.Person[target].Time = WAR.Person[target].Time, WAR.Person[warid].Time
	if WAR.Person[warid]["�ҷ�"] ~= WAR.Person[target]["�ҷ�"] then
		PushBack(warid, time - 1)
	else
		PushBack(warid, time)
	end
end
--�����书
function War_PersonTrainBook(pid)
  local p = JY.Person[pid]
  local thingid = p["������Ʒ"]
  if thingid < 0 then
    return
  end
  JY.Thing[101]["����������"] = 1
  JY.Thing[123]["��ȭ�ƹ���"] = 1
  local wugongid = JY.Thing[thingid]["�����书"]
  local wg = 0
  if JY.Person[pid]["�书12"] > 0 and wugongid >= 0 then
    for i = 1, CC.Kungfunum do
      if JY.Thing[thingid]["�����书"] == JY.Person[pid]["�书" .. i] then
        wg = 1
      end
    end
  if wg == 0 then		--�޸���һ�汾�����������书��BUG
  	return
	end
  end


	local yes1, yes2, kfnum = false, false, nil
	while true do
		local needpoint = TrainNeedExp(pid)
		if needpoint <= p["��������"] then
			yes1 = true
			AddPersonAttrib(pid, "�������ֵ", JY.Thing[thingid]["���������ֵ"])
			--����Ѫ����������
			--���Ʋ���
			if thingid == 139 and match_ID(pid, 37) == false then
				AddPersonAttrib(pid, "�������ֵ", -15)
				AddPersonAttrib(pid, "����", -15)
				if JY.Person[pid]["�������ֵ"] < 1 then
					JY.Person[pid]["�������ֵ"] = 1
				end
			end
			if JY.Person[pid]["����"] < 1 then
				JY.Person[pid]["����"] = 1
			end
			--������С�޲�����
			if JY.Thing[thingid]["�ı���������"] == 2 then
				if thingid == 75 then
					if pid ~= 0 then
						p["��������"] = 2
					end
				else
					p["��������"] = 2
				end
			end

			AddPersonAttrib(pid, "�������ֵ", JY.Thing[thingid]["���������ֵ"])
			AddPersonAttrib(pid, "������", JY.Thing[thingid]["�ӹ�����"])
			AddPersonAttrib(pid, "�Ṧ", JY.Thing[thingid]["���Ṧ"])
			AddPersonAttrib(pid, "������", JY.Thing[thingid]["�ӷ�����"])
			AddPersonAttrib(pid, "ҽ������", JY.Thing[thingid]["��ҽ������"])
			AddPersonAttrib(pid, "�ö�����", JY.Thing[thingid]["���ö�����"])
			AddPersonAttrib(pid, "�ⶾ����", JY.Thing[thingid]["�ӽⶾ����"])
			AddPersonAttrib(pid, "��������", JY.Thing[thingid]["�ӿ�������"])
			if match_ID(pid, 56) or match_ID(pid, 77) then		--���� ���л� ˫������ֵ
				AddPersonAttrib(pid, "ȭ�ƹ���", JY.Thing[thingid]["��ȭ�ƹ���"] * 2)
				AddPersonAttrib(pid, "ָ������", JY.Thing[thingid]["��ָ������"] * 2)
				AddPersonAttrib(pid, "��������", JY.Thing[thingid]["����������"] * 2)
				AddPersonAttrib(pid, "ˣ������", JY.Thing[thingid]["��ˣ������"] * 2)
				AddPersonAttrib(pid, "�������", JY.Thing[thingid]["���������"] * 2)
			else
				AddPersonAttrib(pid, "ȭ�ƹ���", JY.Thing[thingid]["��ȭ�ƹ���"])
				AddPersonAttrib(pid, "ָ������", JY.Thing[thingid]["��ָ������"])
				AddPersonAttrib(pid, "��������", JY.Thing[thingid]["����������"])
				AddPersonAttrib(pid, "ˣ������", JY.Thing[thingid]["��ˣ������"])
				AddPersonAttrib(pid, "�������", JY.Thing[thingid]["���������"])
			end

			AddPersonAttrib(pid, "��������", JY.Thing[thingid]["�Ӱ�������"])
			AddPersonAttrib(pid, "��ѧ��ʶ", JY.Thing[thingid]["����ѧ��ʶ"])
			AddPersonAttrib(pid, "Ʒ��", JY.Thing[thingid]["��Ʒ��"])
			AddPersonAttrib(pid, "��������", JY.Thing[thingid]["�ӹ�������"])
			if JY.Thing[thingid]["�ӹ�������"] == 1 then
			  p["���һ���"] = 1
			end
			p["��������"] = p["��������"] - needpoint

			if wugongid >= 0 then
				yes2 = true
				local oldwugong = 0
				for i = 1, CC.Kungfunum do
					if p["�书" .. i] == wugongid then
						oldwugong = 1
						p["�书�ȼ�" .. i] = math.modf((p["�书�ȼ�" .. i] + 100) / 100) * 100
						kfnum = i
						break;
					end
				end
				if oldwugong == 0 then
					for i = 1, CC.Kungfunum do
						if p["�书" .. i] == 0 then
							p["�书" .. i] = wugongid
							p["�书�ȼ�" .. i] = 0;
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
		DrawStrBoxWaitKey(string.format("%s ���� %s �ɹ�", p["����"], JY.Thing[thingid]["����"]), C_WHITE, CC.DefaultFont)
	end
	if yes2 then
		--�޾Ʋ������Զ��������ж�������
		if p["�书�ȼ�" .. kfnum] == 900 then
			--��쳵��������ж�
			if (match_ID(pid, 1) and wugongid == 67) or (match_ID(pid, 37) and wugongid == 94) or (match_ID(pid, 38) and wugongid == 102) or (match_ID(pid, 49) and wugongid == 14) then
				DrawStrBoxWaitKey(string.format("%s ��Ϊ��%s��", JY.Wugong[wugongid]["����"], math.modf(p["�书�ȼ�" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
			--�ڹ����Ṧ
			elseif JY.Wugong[wugongid]["�书����"] == 6 or JY.Wugong[wugongid]["�书����"] == 7 then
				--��������ֱ�ӵ���
				if wugongid == 85 or wugongid == 87 or wugongid == 88 then
					p["�书�ȼ�" .. kfnum] = 999
					DrawStrBoxWaitKey(string.format("%s ����������", JY.Wugong[wugongid]["����"]), C_WHITE, CC.DefaultFont)
				--����������Ե���
				elseif wugongid == p["�츳�ڹ�"] or wugongid == p["�츳�Ṧ"] then
					p["�书�ȼ�" .. kfnum] = 999
					DrawStrBoxWaitKey(string.format("%s ����������", JY.Wugong[wugongid]["����"]), C_WHITE, CC.DefaultFont)
				else
					DrawStrBoxWaitKey(string.format("%s ��Ϊ��%s��", JY.Wugong[wugongid]["����"], math.modf(p["�书�ȼ�" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
				end
			--�⹦ֱ�ӵ���
			else
				p["�书�ȼ�" .. kfnum] = 999
				DrawStrBoxWaitKey(string.format("%s ����������", JY.Wugong[wugongid]["����"]), C_WHITE, CC.DefaultFont)
			end
		else
			DrawStrBoxWaitKey(string.format("%s ��Ϊ��%s��", JY.Wugong[wugongid]["����"], math.modf(p["�书�ȼ�" .. kfnum] / 100) + 1), C_WHITE, CC.DefaultFont)
		end
	end
end

--��ɫָ��
function War_TgrtsMenu()
	local pid = WAR.Person[WAR.CurID]["������"]
	Cls()
	WAR.ShowHead = 0
	WarDrawMap(0)
	local grts_id;
	--����ǳ���
	if pid == 0 then
		grts_id = JY.Base["����"]
	else
		grts_id = pid
	end

	--�����ָ������
	if match_ID(pid, 626) then
		local wg = JYMsgBox("��ɫָ�" .. GRTS[grts_id], GRTSSAY[grts_id], {"��ָ", "����", "��Ӣ"}, 3, WAR.tmp[5000+WAR.CurID],1)
		if wg == 1 then
			JY.Person[pid]["�书1"] = 18
		elseif wg == 2 then
			JY.Person[pid]["�书1"] = 38
		elseif wg == 3 then
			JY.Person[pid]["�书1"] = 12
		end
		return 0
	else
		local yn = JYMsgBox("��ɫָ�" .. GRTS[grts_id], GRTSSAY[grts_id], {"ȷ��", "ȡ��"}, 2, WAR.tmp[5000+WAR.CurID])
		if yn == 2 then
			return 0
		end
	end

	--����
	if match_ID(pid, 53) then
		if JY.Person[pid]["����"] > 20 then
			WAR.TZ_DY = 1
			PlayWavE(16)
			CurIDTXDH(WAR.CurID, 72,1, "��Ѹ���� Ʈ������", M_DeepSkyBlue, 15);
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--����
	if match_ID(pid, 49) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
		  JY.Person[pid]["����"] = JY.Person[pid]["����"] - 5
		  JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
		  local ssh = {}
		  local num = 1
		  for i = 0, WAR.PersonNum - 1 do
			local wid = WAR.Person[i]["������"]
			if WAR.TZ_XZ_SSH[wid] == 1 and WAR.Person[i]["����"] == false then
				--��Ѩ25��
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
			name[i][1] = JY.Person[ssh[i][2]]["����"]
			name[i][2] = nil
			name[i][3] = 1
		  end
		  DrawStrBox(CC.MainMenuX, CC.MainMenuY, "�߷���", C_GOLD, CC.DefaultFont)
		  ShowMenu(name, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
		  Cls()
		  PlayWavAtk(32)
		  CurIDTXDH(WAR.CurID, 72,1, "�������� ����Ⱥ��")
		  PlayWavE(8)
		  local sssid = lib.SaveSur(0, 0, CC.ScreenW, CC.ScreenH)
		  for DH = 114, 129 do
			for i = 1, num - 1 do
			  local x0 = WAR.Person[WAR.CurID]["����X"]
			  local y0 = WAR.Person[WAR.CurID]["����Y"]
			  local dx = WAR.Person[ssh[i][1]]["����X"] - x0
			  local dy = WAR.Person[ssh[i][1]]["����Y"] - y0
			  local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			  local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
			  local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

			  ry = ry - hb
			  lib.PicLoadCache(3, DH * 2, rx, ry, 2, 192)
			  if DH > 124 then
				DrawString(rx - 10, ry - 15, "��Ѩ", C_GOLD, CC.DefaultFont)
			  end
			end
			lib.ShowSurface(0)
			lib.LoadSur(sssid, 0, 0)
			lib.Delay(30)
		  end
		  lib.FreeSur(sssid)
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

  --�˳���
  if match_ID(pid, 89) then
    if JY.Person[pid]["����"] > 25 and JY.Person[pid]["����"] > 300 then
      local px, py = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
      local mxy = {
					{WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] + 1},
					{WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] - 1},
					{WAR.Person[WAR.CurID]["����X"] + 1, WAR.Person[WAR.CurID]["����Y"]},
					{WAR.Person[WAR.CurID]["����X"] - 1, WAR.Person[WAR.CurID]["����Y"]}}
      local zdp = {}
      local num = 1
      for i = 1, 4 do
        if GetWarMap(mxy[i][1], mxy[i][2], 2) >= 0 then
          local mid = GetWarMap(mxy[i][1], mxy[i][2], 2)
          if inteam(WAR.Person[mid]["������"]) then
          	zdp[num] = WAR.Person[mid]["������"]
          	num = num + 1
        	end
        end

      end
      local zdp2 = {}
      for i = 1, num - 1 do
        zdp2[i] = {}
        zdp2[i][1] = JY.Person[zdp[i]]["����"] .. "��" .. JY.Person[zdp[i]]["����"]
        zdp2[i][2] = nil
        zdp2[i][3] = 1
      end
      DrawStrBox(CC.MainMenuX, CC.MainMenuY, "������", C_GOLD, CC.DefaultFont)
      local r = ShowMenu(zdp2, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
      Cls()
      AddPersonAttrib(zdp[r], "����", 50)
      AddPersonAttrib(pid, "����", -25)
      AddPersonAttrib(pid, "����", -300)
      PlayWavE(28)
      lib.Delay(10)
      CurIDTXDH(WAR.CurID, 86,1, "������Ԫ")
      local Ocur = WAR.CurID
      for i = 0, WAR.PersonNum - 1 do
        if WAR.Person[i]["������"] == zdp[r] then
          WAR.CurID = i
        end
      end
      WarDrawMap(0)
      PlayWavE(36)
      lib.Delay(100)
      CurIDTXDH(WAR.CurID, 86, 1, "�ָ�����50��")
      WAR.CurID = Ocur
      WarDrawMap(0)
    else
    	DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
    	return 0
    end
  end

  --���޼�
  if match_ID(pid, 9) then
    if JY.Person[pid]["����"] > 10 and JY.Person[pid]["����"] > 500 then
      local nyp = {}
      local num = 1
      for i = 0, WAR.PersonNum - 1 do
        if WAR.Person[i]["�ҷ�"] == true and WAR.Person[i]["����"] == false and RealJL(WAR.CurID, i, 8) and i ~= WAR.CurID then
          nyp[num] = {}
          nyp[num][1] = JY.Person[WAR.Person[i]["������"]]["����"]
          nyp[num][2] = nil
          nyp[num][3] = 1
          nyp[num][4] = i
          num = num + 1
        end
      end
      DrawStrBox(CC.MainMenuX, CC.MainMenuY, "Ų�ƣ�", C_GOLD, CC.DefaultFont)
      local r = ShowMenu(nyp, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
      Cls()
      local mid = WAR.Person[nyp[r][4]]["������"]
      QZXS("��ѡ��Ҫ��" .. JY.Person[mid]["����"] .. "Ų�Ƶ�ʲôλ�ã�")
      War_CalMoveStep(WAR.CurID, 8, 1)
      local nx, ny = nil, nil
      while true do
	      nx, ny = War_SelectMove()
	      if nx ~= nil then
		      if lib.GetWarMap(nx, ny, 2) > 0 or lib.GetWarMap(nx, ny, 5) > 0 then
		        QZXS("�˴����ˣ�������ѡ��")			--�˴����ˣ�������ѡ��
	      	elseif CC.SceneWater[lib.GetWarMap(nx, ny, 0)] ~= nil then
	        	QZXS("ˮ�棬���ɽ��룡������ѡ��")		--ˮ�棬���ɽ��룡������ѡ��
	       	else
	       		break;
	        end
	      end
	    end
	    PlayWavE(5)
	    CurIDTXDH(WAR.CurID, 88,1, "�������� Ų��Ǭ��")		--�������� Ų��Ǭ��
	    local Ocur = WAR.CurID
	    WAR.CurID = nyp[r][4]
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] = nx, ny
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
	    lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
	    WarDrawMap(0)
	    CurIDTXDH(WAR.CurID, 88,1)
	    WAR.CurID = Ocur
	    AddPersonAttrib(pid, "����", -10)
	    AddPersonAttrib(pid, "����", -500)

	  else
	  	DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
	  	return 0
	  end
	end

	--��ǧ��
	if match_ID(pid, 88) then
	  if JY.Person[pid]["����"] > 10 and JY.Person[pid]["����"] > 700 then
	    local dxp = {}
	    local num = 1
	    for i = 0, WAR.PersonNum - 1 do
	      if WAR.Person[i]["�ҷ�"] == true and WAR.Person[i]["����"] == false and RealJL(WAR.CurID, i, 5) and i ~= WAR.CurID then
	        dxp[num] = {}
	        dxp[num][1] = JY.Person[WAR.Person[i]["������"]]["����"]
	        dxp[num][2] = nil
	        dxp[num][3] = 1
	        dxp[num][4] = i
	        num = num + 1
	      end
	    end
	    DrawStrBox(CC.MainMenuX, CC.MainMenuY, "������", C_GOLD, 30)
	    local r = ShowMenu(dxp, num - 1, 10, CC.MainMenuX, CC.MainMenuY + 45, 0, 0, 1, 0, CC.DefaultFont, C_RED, C_GOLD)
	    Cls()
	    local mid = WAR.Person[dxp[r][4]]["������"]
	    PlayWavE(28)
	    lib.Delay(10)
	    CurIDTXDH(WAR.CurID,87,1, "����Ϸ�쳾")
	    local Ocur = WAR.CurID
	    WAR.CurID = dxp[r][4]
	    WarDrawMap(0)
	    PlayWavE(36)
	    lib.Delay(100)
	    CurIDTXDH(WAR.CurID, 87, 1, "��������500")
	    WAR.CurID = Ocur
	    WarDrawMap(0)
	    WAR.Person[dxp[r][4]].Time = WAR.Person[dxp[r][4]].Time + 500
	    if WAR.Person[dxp[r][4]].Time > 999 then
	      WAR.Person[dxp[r][4]].Time = 999
	    end
	    AddPersonAttrib(pid, "����", -10)
	    AddPersonAttrib(pid, "����", -1000)
	  else
	  	DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
	  	return 0
		end
	end

	--�����壺����ͩͳ��ָ��ҷ�ȫ�弯��ֵ��200��
	if match_ID(pid, 74) then
		if JY.Person[pid]["����"] > 10 and JY.Person[pid]["����"] > 150 then
			CurIDTXDH(WAR.CurID, 92,1, "ͳ��");		--������ʾ
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["�ҷ�"] == true and WAR.Person[i]["����"] == false and i ~= WAR.CurID then
					WAR.Person[i].Time = WAR.Person[i].Time + 200;
					if WAR.Person[i].Time > 999 then
						WAR.Person[i].Time = 999;
					end
				end
			end
			AddPersonAttrib(pid, "����", -10)
			AddPersonAttrib(pid, "����", -150)
			lib.Delay(100)
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
	  	return 0
		end
	end

	--���лۣ�����
	if match_ID(pid, 77) then
		if JY.Person[pid]["����"] > 500 and JY.Person[pid]["���˳̶�"] < 50 then
			local zjwid = nil
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["������"] == 0 and WAR.Person[i]["����"] == false then
					zjwid = i
					break
				end
			end
			if zjwid ~= nil then
				DrawStrBoxWaitKey("���ı��ۡ���Ů����", C_RED, 36)
				say("�����á�����",0,1)
				if JY.Person[0]["�Ա�"] == 0 then
					say("�����磬���롭�����������ͣ�",77,0)
				else
					say("�����㣬���롭�����������ͣ�",77,0)
				end
				JY.Person[pid]["����"] = 1
				JY.Person[pid]["���˳̶�"] = 100
				WAR.Person[WAR.CurID].Time = -500
				JY.Person[0]["����"] = JY.Person[0]["�������ֵ"]
				JY.Person[0]["���˳̶�"] = 0
				WAR.Person[zjwid].Time = 999
				WAR.FXDS[0] = nil
				WAR.LQZ[0] = 100
			else
				DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)		-- "δ���㷢������"
				return 0
			end

		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)		-- "δ���㷢������"
			return 0
		end
	end

	--�����壺���ѹ���ɫָ�� - ʩ��  ��Χ���Χ�ڵĵ���ʱ���ж���ʱ���Ѫ
	if match_ID(pid, 17) then
		if JY.Person[pid]["����"] >= 30 and JY.Person[pid]["����"] >= 300 then
			CleanWarMap(4,0);
			AddPersonAttrib(pid, "����", -15)
			AddPersonAttrib(pid, "����", -300)
			local x1 = WAR.Person[WAR.CurID]["����X"];
			local y1 = WAR.Person[WAR.CurID]["����Y"];
			for ex = x1 - 5, x1 + 5 do
				for ey = y1 - 5, y1 + 5 do
					SetWarMap(ex, ey, 4, 1)
					if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
						local ep = GetWarMap(ex, ey, 2)
						if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[ep]["�ҷ�"] then

							WAR.L_WNGZL[WAR.Person[ep]["������"]] = 50;			--50ʱ���ڳ������ж�+��Ѫ
							SetWarMap(ex, ey, 4, 4)
						end
					end
				end
			end
			War_ShowFight(pid,0,0,0,x1,y1,30);
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--brolycjw������ţ��ɫָ�� - Ⱥ��  ��Χ���Χ�ڵĶ���ʱ������˲���������Ѫ
	if match_ID(pid, 16) then
		if JY.Person[pid]["����"] >= 30 and JY.Person[pid]["����"] >= 300 then
			CleanWarMap(4,0);
			AddPersonAttrib(pid, "����", -15)
			AddPersonAttrib(pid, "����", -300)
			local x1 = WAR.Person[WAR.CurID]["����X"];
			local y1 = WAR.Person[WAR.CurID]["����Y"];

			for ex = x1 - 5, x1 + 5 do
				for ey = y1 - 5, y1 + 5 do
					SetWarMap(ex, ey, 4, 1)
					if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
						local ep = GetWarMap(ex, ey, 2)
						if WAR.Person[WAR.CurID]["�ҷ�"] == WAR.Person[ep]["�ҷ�"] then

							WAR.L_HQNZL[WAR.Person[ep]["������"]] = 20;			--20ʱ���ڳ�����Ѫ+������
							SetWarMap(ex, ey, 4, 4)

						end
					end
				end
			end
			War_ShowFight(pid,0,0,0,x1,y1,0);

		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--Ľ�ݸ� ����
	if match_ID(pid, 51) then
		if JY.Person[pid]["����"] > 20 then
			WAR.TZ_MRF = 1
			CurIDTXDH(WAR.CurID, 127,1, "���������� ���Ǹ���־", C_GOLD);
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--С�� Ӱ��
	if match_ID(pid, 66) then
		if JY.Person[pid]["����"] > 30 and JY.Person[pid]["����"] > 2000 then
			War_CalMoveStep(WAR.CurID, 10, 0)
			WAR.XZ_YB[1],WAR.XZ_YB[2]=War_SelectMove()
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 20
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 1000
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--����ָ�� ����
	if match_ID(pid, 90) then
		if JY.Person[pid]["����"] > 10 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
					return 0
				end
				local eid = WAR.Person[tdID]["������"]
				local x0, y0 = WAR.Person[WAR.CurID]["����X"],WAR.Person[WAR.CurID]["����Y"]
				local x1, y1 = WAR.Person[tdID]["����X"],WAR.Person[tdID]["����Y"]
				for i = 1, 4 do
					if 0 < JY.Person[eid]["Я����Ʒ����" .. i] and -1 < JY.Person[eid]["Я����Ʒ" .. i] then
						WAR.TD = JY.Person[eid]["Я����Ʒ" .. i]
						WAR.TDnum = JY.Person[eid]["Я����Ʒ����" .. i]
						JY.Person[eid]["Я����Ʒ����" .. i] = 0
						JY.Person[eid]["Я����Ʒ" .. i] = -1
						break
					end
				end
				WAR.Person[WAR.CurID]["�˷���"] = War_Direct(x0, y0, x1, y1)
				CleanWarMap(4, 0)
				SetWarMap(x1, y1, 4, 1)
				WAR.Person[tdID]["�ж�����"] = (WAR.Person[tdID]["�ж�����"] or 0) + AddPersonAttrib(eid, "�ж��̶�", 50)
				WAR.TXXS[eid] = 1
				War_ShowFight(WAR.Person[WAR.CurID]["������"], 0, 0, 0, 0, 0, 12)
				if WAR.TD ~= -1 then
					if WAR.TD == 118 then
						say("����Ҫ����Ľ�ݸ�����͵�������ߺߣ��±��Ӱɣ�", 51,0)
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
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 5
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--��� �ɺ�
	if match_ID(pid, 1) then
		if JY.Person[pid]["����"] > 20 then
			War_CalMoveStep(WAR.CurID, 10, 2)
			local x,y = War_SelectMove()
			if not x then
				return 0
			end
			if GetWarMap(x, y, 1) > 0 or GetWarMap(x, y, 2) > 0 or GetWarMap(x, y, 5) > 0 or CC.WarWater[GetWarMap(x, y, 0)] ~= nil then
				return 0
			else
				CurIDTXDH(WAR.CurID, 25,1, "ѩɽ�ɺ�", Violet);
				WAR.Person[WAR.CurID]["�ƶ�����"] = 10
				War_MovePerson(x, y, 1)
				WAR.Person[WAR.CurID]["�ƶ�����"] = 0
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			end
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--�Ħ�� �û�
	if match_ID(pid, 103) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			local thing = {}
			local thingnum = {}
			for i = 0, CC.MyThingNum - 1 do
				thing[i] = -1
				thingnum[i] = 0
			end
			local num = 0
			for i = 0, CC.MyThingNum - 1 do
				local id = JY.Base["��Ʒ" .. i + 1]
				if id >= 0 then
					if JY.Thing[id]["����"] == 2 and JY.Thing[id]["�����书"] > -1 then
						thing[num] = id
						thingnum[num] = JY.Base["��Ʒ����" .. i + 1]
						num = num + 1
					end
				end
			end
			IsViewingKungfuScrolls = 1
			local r = SelectThing(thing, thingnum)
			if r >= 0 then
				CurIDTXDH(WAR.CurID, 93,1, "����û�", C_GOLD)
				JY.Person[pid]["�书2"]= JY.Thing[r]["�����书"]
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--�����ָ�� ��ս
	if match_ID(pid, 160) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
					return 0
				end
				local eid = WAR.Person[tdID]["������"]
				WAR.SZSD = eid

				CurIDTXDH(WAR.CurID, 93,1, "����Ŀ��", C_GOLD)
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--���� ����
	if match_ID(pid, 62) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			War_ActupMenu()
			WAR.SLSX[pid] = 2
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--���� �ݼ�
	if match_ID(pid, 56) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			local x,y = WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"]
			--1��ɫ��2��ɫ��3��ɫ��4��ɫ
			CleanWarMap(6,-1);

			local QMDJ = {"��","��","��","��","��","��","��","��"}

			--��������Χ��������
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
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--���ϣ���ҩ
	if match_ID(pid, 47) then
		WAR.JYZT[pid] = 1
		CurIDTXDH(WAR.CurID, 128,1, "��ҩ", C_RED);
		return 20
	end

	--ΤС�� �ڲ�
	if match_ID(pid, 601) then
		if JY.Person[pid]["����"] > 30 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
					return 0
				end
				local eid = WAR.Person[tdID]["������"]
				WAR.CSZT[eid] = 1

				Cls()
				local KC = {"����Ӣ������","��������"}

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
				JY.Person[pid]["����"] = JY.Person[pid]["����"] - 15
			else
				return 0
			end
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--���˷�ָ�� �ƾ�
	if match_ID(pid, 3) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			WAR.MRF = 1
			if War_FightMenu() == 0 then
				return 0
			end
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 300
			WAR.MRF = 0
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--��������
	if match_ID(pid, 6) then
		WAR.YSJF[pid] = 100
		CurIDTXDH(WAR.CurID, 124,1, "��ʯ���", M_Silver);
		return 20
	end

	--лѷָ�� ����
	if match_ID(pid, 13) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 3000 then
			CurIDTXDH(WAR.CurID, 118,1, "ʨ������", C_GOLD)
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[j]["����"] == false then
					WAR.HLZT[WAR.Person[j]["������"]] = 20
				end
			end
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 2000
			WAR.MRF = 0
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--��̫��ָ�� ����
	if match_ID(pid, 7) then
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			CleanWarMap(4, 0)
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
					local eid = WAR.Person[j]["������"]
					local qycs = WAR.QYZT[eid] or 0
					if qycs > 0 then
						WAR.TXXS[eid] = 1
						--�޾Ʋ�������¼����Ѫ��
						WAR.Person[j]["Life_Before_Hit"] = JY.Person[eid]["����"]
						JY.Person[eid]["����"] = JY.Person[eid]["����"] - 50*qycs
						WAR.Person[j]["��������"] = (WAR.Person[j]["��������"] or 0) - 50*qycs
						SetWarMap(WAR.Person[j]["����X"], WAR.Person[j]["����Y"], 4, 1)
						WAR.QYZT[eid] = nil
					end
				end
			end
			War_ShowFight(WAR.Person[WAR.CurID]["������"], 0, 0, 0, 0, 0, 144)
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--�ֻ�ָ�� ����
	if match_ID(pid, 4) then
		if JY.Person[pid]["����"] > 20 then
			War_CalMoveStep(WAR.CurID, 8, 1)
			local x,y = War_SelectMove()
			if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
				local tdID = lib.GetWarMap(x, y, 2)
				if WAR.Person[tdID]["�ҷ�"] == WAR.Person[WAR.CurID]["�ҷ�"] then
					return 0
				end
				local eid = WAR.Person[tdID]["������"]
				local x0, y0 = WAR.Person[WAR.CurID]["����X"],WAR.Person[WAR.CurID]["����Y"]
				local x1, y1 = WAR.Person[tdID]["����X"],WAR.Person[tdID]["����Y"]

				WAR.XRZT[eid] = 30
				WAR.Person[WAR.CurID]["�˷���"] = War_Direct(x0, y0, x1, y1)
				CleanWarMap(4, 0)
				SetWarMap(x1, y1, 4, 1)
				War_ShowFight(WAR.Person[WAR.CurID]["������"], 0, 0, 0, 0, 0, 148)
			else
				return 0
			end
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--���˿�����
	if match_ID(pid, 15) then
		WAR.QGZT[pid] = 6
		CurIDTXDH(WAR.CurID, 149,1)
		JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
	end

	--����ָ�� Ůװ
	if match_ID(pid, 92) then
		if JY.Person[pid]["����"] > 20 then
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "�ճ����� Ψ���㲻��", C_GOLD)
			lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
			lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
			WarDrawMap(0)
			local mj = {}
			if JY.Person[pid]["�Ա�"] == 0 then
				JY.Person[pid]["ͷ�����"] = 384
				JY.Person[pid]["�Ա�"] = 1
				JY.Person[pid]["�书2"] = 154
				JY.Person[pid]["�츳�ڹ�"] = 154
				JY.Person[pid]["�����ڹ�"] = 154
				mj[1]={0,15,0,0,0}
				mj[2]={0,13,0,0,0}
				mj[3]={0,13,0,0,0}
			else
				JY.Person[pid]["ͷ�����"] = 387
				JY.Person[pid]["�Ա�"] = 0
				JY.Person[pid]["�书2"] = 105
				JY.Person[pid]["�츳�ڹ�"] = 105
				JY.Person[pid]["�����ڹ�"] = 105
				mj[1]={0,14,0,0,0}
				mj[2]={0,12,0,0,0}
				mj[3]={0,12,0,0,0}
			end
			for i = 1, 5 do
				JY.Person[pid]["���ж���֡��" .. i] = mj[1][i]
				JY.Person[pid]["���ж����ӳ�" .. i] = mj[2][i]
				JY.Person[pid]["�书��Ч�ӳ�" .. i] = mj[3][i]
			end
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["������"] == 92 then
					lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[pid]["ͷ�����"]), string.format(CC.FightPicFile[2], JY.Person[pid]["ͷ�����"]), 4 + i)
					WAR.tmp[5000+i] = JY.Person[pid]["ͷ�����"]
					break
				end
			end
			WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "�ճ����� Ψ���㲻��", C_GOLD)
			lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
			lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
			WarDrawMap(0)
			CurIDTXDH(WAR.CurID, 135, 1, "�ճ����� Ψ���㲻��", C_GOLD)
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	--��֤ ����
	if match_ID(pid, 149) then
		if WAR.JSBM[pid] ~= nil then
			WAR.JSBM[pid] = nil
			return 20
		end
		if JY.Person[pid]["����"] > 20 and JY.Person[pid]["����"] > 1000 then
			WAR.JSBM[pid] = 1
			CurIDTXDH(WAR.CurID, 78,1,"������",C_GOLD)
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 10
			JY.Person[pid]["����"] = JY.Person[pid]["����"] - 500
			return 20
		else
			DrawStrBoxWaitKey("δ���㷢������", C_WHITE, CC.DefaultFont)
			return 0
		end
	end

	return 1
end

--ս������
function War_ActupMenu()
	local p = WAR.CurID
	local id = WAR.Person[p]["������"]
	local x0, y0 = WAR.Person[p]["����X"], WAR.Person[p]["����Y"]

	--�����Ƿ��ڳ�
	local ZM = 0
	if inteam(id) then
		for i = 0, WAR.PersonNum - 1 do
			local zid = WAR.Person[i]["������"]
			if WAR.Person[i]["����"] == false and WAR.Person[i]["�ҷ�"] == false then
				JY.Person[zid]["����"] = 0
			end
		end
	end

	--���˸������������Ч��
	if Curr_NG(id, 95) then
		WAR.Actup[id] = 2;
		WAR.Defup[id] = 1
		WAR.HMGXL[id] = 1
		CurIDTXDH(WAR.CurID, 85,1);
		DrawStrBox(-1, -1, "���ؼ汸�����ƴ���", LightSlateBlue, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--������ϼ����ǿ��
	elseif PersonKF(id, 89) then
		WAR.Actup[id] = 2
		if inteam(id) then
			WAR.ZXXS[id] = 1 + math.modf(JY.Base["��������"]/7)
		else
			WAR.ZXXS[id] = 3
		end
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "��ϼ���ơ����಻��", Violet, CC.DefaultFont, M_DeepSkyBlue)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--������������������Ч��
	elseif PersonKF(id, 103) then
		WAR.Actup[id] = 2;
		WAR.Defup[id] = 1
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "��֮��������֮����", LightGreen, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
		return 1;
	--���������سɹ�
	elseif id == 0 and JY.Base["��׼"] > 0 then
		WAR.Actup[id] = 2
	--NPC�����سɹ�
	elseif not inteam(id) then
		WAR.Actup[id] = 2
	--�ҷ��������ڳ��سɹ�
	elseif inteam(id) and ZM == 1 then
		WAR.Actup[id] = 2
	--��̬70%���ʳɹ�
	elseif JLSD(15, 85, id) then
		WAR.Actup[id] = 2
	end
	if WAR.Actup[id] ~= 2 then
		Cls()
		DrawStrBox(-1, -1, "����ʧ��", C_GOLD, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
	else
		CurIDTXDH(WAR.CurID, 85, 1);
		DrawStrBox(-1, -1, "�����ɹ�", C_GOLD, CC.DefaultFont)
		ShowScreen()
		lib.Delay(400)
	end
	return 1
end


--ս������
function War_DefupMenu()
	local p = WAR.CurID
	local id = WAR.Person[p]["������"]
	local x0, y0 = WAR.Person[p]["����X"], WAR.Person[p]["����Y"]
	WAR.Defup[id] = 1
	Cls()
	local hb = GetS(JY.SubScene, x0, y0, 4)

	--̫������������
	if PersonKF(id, 102) then
		WAR.Actup[id] = 2;
		CurIDTXDH(WAR.CurID, 86,1);
		DrawStrBox(-1, -1, "������ʼ��̫������", C_RED, CC.DefaultFont, C_GOLD)
		ShowScreen()
		lib.Delay(400)
		return 1;
	end

	CurIDTXDH(WAR.CurID, 86,1);
	DrawStrBox(-1, -1, "������ʼ", LimeGreen, CC.DefaultFont, C_GOLD)
	ShowScreen()
	lib.Delay(400)
	return 1
end

--��������ļ���ֵ������һ���ۺ�ֵ�Ա�ѭ��ˢ�¼�����
function GetJiqi()
	local num, total = 0, 0
	for i = 0, WAR.PersonNum - 1 do
		if not WAR.Person[i]["����"] then
			local id = WAR.Person[i]["������"]
			WAR.Person[i].TimeAdd = 20

			num = num + 1
			total = total + WAR.Person[i].TimeAdd
		end
	end

	--�޾Ʋ������������ֵ��ﲻ��ȷ������
	WAR.LifeNum = num
	return math.modf(((total) / (num) + (num) - 2))
end


--�书��Χѡ��
function War_KfMove(movefanwei, atkfanwei, wugong)
  local kind = movefanwei[1] or 0
  local len = movefanwei[2] or 0
  local negativelen = movefanwei[3] or 0
  local x0 = WAR.Person[WAR.CurID]["����X"]
  local y0 = WAR.Person[WAR.CurID]["����Y"]
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

	--�жϺϻ����ж��Ƿ��кϻ���

	local ZHEN_ID = -1;
    
	WarDrawMap(1, x, y)
    WarShowHead(GetWarMap(x, y, 2))
	
	--�ϻ��˱�ʶ
	if ZHEN_ID ~= -1 then
		local nx = WAR.Person[ZHEN_ID]["����X"]
		local ny = WAR.Person[ZHEN_ID]["����Y"]
		local dx = nx - x0
		local dy = ny - y0
		local size = CC.FontSmall;
		local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
		local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
									
		local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
									
		DrawString(rx - size*1.5, ry-hb-size/2, "�ϻ���", M_DeepSkyBlue, size);
	end

	--��ʾ���Ը��ǵĵ�����Ϣ
	for i = 0, CC.WarWidth - 1 do
		for j = 0, CC.WarHeight - 1 do
			local target = GetWarMap(i, j, 7)
			if target ~= nil and target == 2 then
				if GetWarMap(i, j, 2) ~= nil and WAR.Person[GetWarMap(i, j, 2)]["������"] ~= nil then
					local x0 = WAR.Person[WAR.CurID]["����X"];
					local y0 = WAR.Person[WAR.CurID]["����Y"];
					local dx = i - x0
					local dy = j - y0
					local size = CC.FontSmall;
					local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
					local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

					local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

					ry = ry - hb - CC.ScreenH/6;

					if ry < 1 then			--�����������ֹ������Ѫ�����
						ry = 1;
					end

					--��ʾѡ�����������ֵ
					local color = RGB(245, 251, 5);
					local hp = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["������"]]["����"] or 0;
					local maxhp = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["������"]]["�������ֵ"] or 0;

					local ns = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["������"]]["���˳̶�"] or 0;
					local zd = JY.Person[WAR.Person[GetWarMap(i, j, 2)]["������"]]["�ж��̶�"] or 0;
					local len = #(string.format("%d/%d",hp,maxhp));
					rx = rx - len*size/4;

					--��ɫ�������ܵ�����ȷ��
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
		if WAR.Person[GetWarMap(x, y, 2)] ~= nil and WAR.Person[GetWarMap(x, y, 2)]["�ҷ�"] == false then
			local distance = math.abs(x-x0) + math.abs(y-y0)
			if distance <= negativelen then
				DrawStrBoxWaitKey("���书��С����Ϊ"..(negativelen + 1), C_WHITE, CC.DefaultFont)
			else
				return x, y
			end
		else
			DrawStrBoxWaitKey("��ָ������ΪĿ��", C_WHITE, CC.DefaultFont)
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
	      	if WAR.Person[GetWarMap(x, y, 2)] ~= nil and WAR.Person[GetWarMap(x, y, 2)]["�ҷ�"] == false then
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
    x0 = WAR.Person[WAR.CurID]["����X"]
    y0 = WAR.Person[WAR.CurID]["����Y"]
  else
    x0, y0 = cx, cy
  end
  local kind = fanwei[1]			--������Χ
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
				if not inteam(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]) and WAR.Person[WAR.CurID]["�ҷ�"] then
		      	local x0 = WAR.Person[WAR.CurID]["����X"];
		      	local y0 = WAR.Person[WAR.CurID]["����Y"];
		      	local dx = xy[i][1] - x0
		        local dy = xy[i][2] - y0
		        local size = CC.FontSmall;
		        local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
		        local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

		        local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

		        ry = ry - hb - CC.ScreenH/6;

		        if ry < 1 then			--�����������ֹ������Ѫ�����
		        	ry = 1;
		        end

		      	--��ʾѡ�����������ֵ
		      	local color = RGB(245, 251, 5);
		      	local hp = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]]["����"];
		      	local maxhp = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]]["�������ֵ"];

		      	local ns = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]]["���˳̶�"];
		      	local zd = JY.Person[WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]]["�ж��̶�"];
		      	local len = #(string.format("%d/%d",hp,maxhp));
		      	rx = rx - len*size/4;

		      	--��ɫ�������ܵ�����ȷ��
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
    local diwo = WAR.Person[WAR.CurID]["�ҷ�"]
    local atknum = 0
    for i = 1, num do
      if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
        local id = GetWarMap(xy[i][1], xy[i][2], 2)

	      if id ~= -1 and id ~= WAR.CurID then
	        local xa, xb, xc = nil, nil, nil
	        if diwo ~= WAR.Person[id]["�ҷ�"] then
	          xa = 2
	        else
	          if GetS(0, 0, 0, 0) == 1 then
	            xa = -0.5
		        else
		          xa = 0
		        end
	        end
	        local hp = JY.Person[WAR.Person[id]["������"]]["����"]
	        if hp < atk / 6 then
	          xb = 2
	        elseif hp < atk / 3 then
	          xb = 1
	        else
	          xb = 0
	        end
	        local danger = JY.Person[WAR.Person[id]["������"]]["�������ֵ"]
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
	--�书ѡ��Χ
  elseif flag == 4 then
    for i = 1, num do
    	if xy[i][1] >= 0 and xy[i][1] < CC.WarWidth and xy[i][2] >= 0 and xy[i][2] < CC.WarHeight then
			if GetWarMap(xy[i][1], xy[i][2], 2) ~= nil and GetWarMap(xy[i][1], xy[i][2], 2) >= 0 then
				--��Ϧ��Ů���۽����������Ƿ�ѧ�����ٲ�
				--�Զ�������
				if WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"] == 0 and JY.Person[615]["�۽�����"] == 1 and math.random(10) < 4 and WAR.AutoFight == 0 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["�ҷ�"] then
					--�ð������Ʒ����Ϊ�������ٲ����ж�
					JY.Person[606]["Ʒ��"] = 90
				end
				--С��Ӱ��
				if match_ID(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"], 66) and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["�ҷ�"] then
					--��С�ѵ�Ʒ����Ϊ����Ӱ�����ж�
					JY.Person[66]["Ʒ��"] = 90
				end
				--�������޼���תǬ��
				--�Զ�������
				if WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"] == 0 and JY.Base["����"] == 9 and PersonKF(0, 97) and WAR.AutoFight == 0 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["�ҷ�"] then
					--����35%����
					local chance = 36
					--ÿ������+1����
					chance = chance + JY.Base["��������"]
					if WAR.LQZ[0] == 100 then
						chance = chance + 10
					end
					if math.random(100) < chance then
						JY.Person[614]["Ʒ��"] = 90
					end
				end
				--���еĵз��ĵ�Ϊ2
				if not inteam(WAR.Person[GetWarMap(xy[i][1], xy[i][2], 2)]["������"]) and WAR.Person[WAR.CurID]["�ҷ�"] then
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

--��а���
PNLBD[0] = function()
  JY.Person[1]["����"] = 800
  JY.Person[1]["�������ֵ"] = 800
  JY.Person[1]["����"] = 4000
  JY.Person[1]["�������ֵ"] = 4000
  JY.Person[1]["������"] = 130
  JY.Person[1]["������"] = 130
  JY.Person[1]["�Ṧ"] = 160
  JY.Person[1]["���˳̶�"] = 0
  JY.Person[1]["�ж��̶�"] = 0
  JY.Person[1]["�书1"] = 67
  JY.Person[1]["�书�ȼ�1"] = 999
  JY.Person[1]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--�����ֻ�
PNLBD[1] = function()
  JY.Person[4]["����"] = 330
  JY.Person[4]["�������ֵ"] = 330
  JY.Person[4]["����"] = 1200
  JY.Person[4]["�������ֵ"] = 1200
  JY.Person[4]["�书�ȼ�1"] = 700
  JY.Person[4]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--ɱ��ƽ֮
PNLBD[34] = function()
  JY.Person[36]["����"] = 650
  JY.Person[36]["�������ֵ"] = 650
  JY.Person[36]["����"] = 3000
  JY.Person[36]["�������ֵ"] = 3000
  JY.Person[36]["������"] = 180
  JY.Person[36]["������"] = 130
  JY.Person[36]["�Ṧ"] = 220
  JY.Person[36]["���˳̶�"] = 0
  JY.Person[36]["�ж��̶�"] = 0
  JY.Person[36]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��аս����
PNLBD[75] = function()
  JY.Person[58]["����"] = 850
  JY.Person[58]["�������ֵ"] = 850
  JY.Person[58]["����"] = 4000
  JY.Person[58]["�������ֵ"] = 4000
  JY.Person[58]["������"] = 210
  JY.Person[58]["������"] = 180
  JY.Person[58]["�Ṧ"] = 160
  JY.Person[58]["���˳̶�"] = 0
  JY.Person[58]["�ж��̶�"] = 0
  JY.Person[58]["�书1"] = 45		--����
  JY.Person[58]["�书2"] = 104		--����
  JY.Person[58]["�书3"] = 107		--����
  JY.Person[58]["�书�ȼ�1"] = 999
  JY.Person[58]["�书�ȼ�2"] = 999
  JY.Person[58]["�书�ȼ�3"] = 400
  JY.Person[58]["Ѫ������"] = JY.Person[592]["Ѫ������"]
  JY.Person[59]["����"] = 750
  JY.Person[59]["�������ֵ"] = 750
  JY.Person[59]["����"] = 3500
  JY.Person[59]["�������ֵ"] = 3500
  JY.Person[59]["������"] = 170
  JY.Person[59]["������"] = 150
  JY.Person[59]["�Ṧ"] = 200
  JY.Person[59]["���˳̶�"] = 0
  JY.Person[59]["�ж��̶�"] = 0
  JY.Person[59]["�书3"] = 107		--����
  JY.Person[59]["�书�ȼ�3"] = 400
  JY.Person[59]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--���׹���
PNLBD[76] = function()
	JY.Person[55]["�书1"] = 26
	JY.Person[55]["�书�ȼ�1"] = 600
    JY.Person[55]["�书2"] = 15
	JY.Person[55]["�书�ȼ�2"] = 500
    JY.Person[55]["�书3"] = 107
	JY.Person[55]["�书�ȼ�3"] = 50
	JY.Person[55]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��а�¼���
PNLBD[138] = function()
  JY.Person[75]["����"] = 650
  JY.Person[75]["�������ֵ"] = 650
  JY.Person[75]["����"] = 3000
  JY.Person[75]["�������ֵ"] = 3000
  JY.Person[75]["������"] = 140
  JY.Person[75]["������"] = 120
  JY.Person[75]["�Ṧ"] = 130
  JY.Person[75]["���˳̶�"] = 0
  JY.Person[75]["�ж��̶�"] = 0
  JY.Person[75]["�书�ȼ�1"] = 999
  JY.Person[75]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��а
PNLBD[165] = function()
	--Ԭ��־
	JY.Person[54]["����"] = 750
	JY.Person[54]["�������ֵ"] = 750
	JY.Person[54]["����"] = 4000
	JY.Person[54]["�������ֵ"] = 4000
	JY.Person[54]["������"] = 140
	JY.Person[54]["������"] = 140
	JY.Person[54]["�Ṧ"] = 90
	JY.Person[54]["���˳̶�"] = 0
	JY.Person[54]["�ж��̶�"] = 0
	JY.Person[54]["���˾���"] = 1
	JY.Person[54]["Я����Ʒ1"] = -1
	JY.Person[54]["Я����Ʒ2"] = -1
	JY.Person[54]["Я����Ʒ����1"] = 0
	JY.Person[54]["Я����Ʒ����2"] = 0
	JY.Person[54]["Ѫ������"] = JY.Person[592]["Ѫ������"]
	--������
	JY.Person[91]["����"] = 600
	JY.Person[91]["�������ֵ"] = 600
	JY.Person[91]["����"] = 2500
	JY.Person[91]["�������ֵ"] = 2500
	JY.Person[91]["������"] = 110
	JY.Person[91]["������"] = 110
	JY.Person[91]["�Ṧ"] = 70
	JY.Person[91]["���˳̶�"] = 0
	JY.Person[91]["�ж��̶�"] = 0
	JY.Person[91]["�书1"] = 40
	JY.Person[91]["�书�ȼ�1"] = 999
	JY.Person[91]["�书2"] = 90
	JY.Person[91]["�书�ȼ�2"] = 999
	JY.Person[91]["�츳�ڹ�"] = 90
	for i = 3 , 12 do
		JY.Person[91]["�书"..i] = 0
		JY.Person[91]["�书�ȼ�"..i] = 0
	end
	JY.Person[91]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��аʯ����
PNLBD[170] = function()
  JY.Person[38]["����"] = 950
  JY.Person[38]["�������ֵ"] = 950
  JY.Person[38]["����"] = 5000
  JY.Person[38]["�������ֵ"] = 5000
  JY.Person[38]["������"] = 200
  JY.Person[38]["������"] = 200
  JY.Person[38]["�Ṧ"] = 160
  JY.Person[38]["���˳̶�"] = 0
  JY.Person[38]["�ж��̶�"] = 0
  JY.Person[38]["�书�ȼ�1"] = 999
  JY.Person[38]["�书2"] = 102
  JY.Person[38]["�书�ȼ�2"] = 999
  JY.Person[38]["�츳�ڹ�"] = 102
  JY.Person[38]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--������̹֮
PNLBD[197] = function()
  JY.Person[48]["����"] = 850
  JY.Person[48]["�������ֵ"] = 850
  JY.Person[48]["����"] = 3000
  JY.Person[48]["�������ֵ"] = 3000
  JY.Person[48]["������"] = 150
  JY.Person[48]["������"] = 130
  JY.Person[48]["�Ṧ"] = 100
  JY.Person[48]["���˳̶�"] = 0
  JY.Person[48]["�ж��̶�"] = 0
  JY.Person[48]["�书�ȼ�1"] = 999
  JY.Person[48]["�书�ȼ�2"] = 999
  JY.Person[48]["�书2"] = 108
  JY.Person[48]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--����Ľ�ݸ�
PNLBD[198] = function()
  JY.Person[51]["����"] = 750
  JY.Person[51]["�������ֵ"] = 750
  JY.Person[51]["����"] = 3000
  JY.Person[51]["�������ֵ"] = 3000
  JY.Person[51]["������"] = 180
  JY.Person[51]["������"] = 160
  JY.Person[51]["�Ṧ"] = 120
  JY.Person[51]["���˳̶�"] = 0
  JY.Person[51]["�ж��̶�"] = 0
  JY.Person[51]["�书�ȼ�1"] = 999
  JY.Person[51]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��а��
PNLBD[250] = function()
	--����
	JY.Person[53]["����"] = 750
	JY.Person[53]["�������ֵ"] = 750
	JY.Person[53]["����"] = 9999
	JY.Person[53]["�������ֵ"] = 9999
	JY.Person[53]["������"] = 160
	JY.Person[53]["������"] = 150
	JY.Person[53]["�Ṧ"] = 120
	JY.Person[53]["�书1"] = 85
	JY.Person[53]["�书�ȼ�1"] = 999
	JY.Person[53]["�书2"] = 147
	JY.Person[53]["�书�ȼ�2"] = 999
	JY.Person[53]["�书3"] = 49
	JY.Person[53]["�书�ȼ�3"] = 999
	JY.Person[53]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��а��
PNLBD[251] = function()
	--����
	JY.Person[49]["����"] = 800
	JY.Person[49]["�������ֵ"] = 800
	JY.Person[49]["����"] = 8500
	JY.Person[49]["�������ֵ"] = 8500
	JY.Person[49]["������"] = 150
	JY.Person[49]["������"] = 170
	JY.Person[49]["�Ṧ"] = 80
	JY.Person[49]["���˳̶�"] = 0
	JY.Person[49]["�ж��̶�"] = 0
	JY.Person[49]["�书1"] = 8
	JY.Person[49]["�书�ȼ�1"] = 999
	JY.Person[49]["�书2"] = 98
	JY.Person[49]["�书�ȼ�2"] = 999
	JY.Person[49]["�书3"] = 14
	JY.Person[49]["�书�ȼ�3"] = 999
	JY.Person[49]["�书4"] = 101
	JY.Person[49]["�书�ȼ�4"] = 999
	for i = 5 , 12 do
		JY.Person[49]["�书"..i] = 0
		JY.Person[49]["�书�ȼ�"..i] = 0
	end
	JY.Person[49]["���˾���"] = 1
	JY.Person[49]["���һ���"] = 0
	JY.Person[49]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��аˮ��
PNLBD[42] = function()
	JY.Person[589]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

PNLBD[252] = function()
	JY.Person[589]["�������ֵ"] = 650
	JY.Person[589]["����"] = JY.Person[589]["�������ֵ"]
	JY.Person[589]["�������ֵ"] = 2500
	JY.Person[589]["����"] = JY.Person[589]["�������ֵ"]
	JY.Person[589]["������"] = 130
	JY.Person[589]["�Ṧ"] = 120
	JY.Person[589]["�书�ȼ�1"] = 999
end

--��а���޼�
PNLBD[288] = function()
	JY.Person[9]["�������ֵ"] = 999
	JY.Person[9]["����"] = JY.Person[9]["�������ֵ"]
	JY.Person[9]["�������ֵ"] = 5000
	JY.Person[9]["����"] = JY.Person[9]["�������ֵ"]
	JY.Person[9]["������"] = 220
	JY.Person[9]["������"] = 200
	JY.Person[9]["�Ṧ"] = 200
	JY.Person[9]["�书�ȼ�1"] = 999
	JY.Person[9]["�书�ȼ�2"] = 999
	JY.Person[9]["�书3"] = 97
	JY.Person[9]["�书�ȼ�3"] = 900
	JY.Person[9]["�书4"] = 16
	JY.Person[9]["�书�ȼ�4"] = 999
	JY.Person[9]["�书5"] = 46
	JY.Person[9]["�书�ȼ�5"] = 999
	JY.Person[9]["�书6"] = 93
	JY.Person[9]["�书�ȼ�6"] = 900
	JY.Person[9]["Я����Ʒ1"] = -1
	JY.Person[9]["Я����Ʒ����1"] = 0
	JY.Person[9]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--������
--����
PNLBD[162] = function()
  JY.Person[83]["����"] = 600
  JY.Person[83]["�������ֵ"] = 600
  JY.Person[83]["����"] = 3500
  JY.Person[83]["�������ֵ"] = 3500
  JY.Person[83]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end
--а��
PNLBD[164] = function()
  JY.Person[83]["����"] = 600
  JY.Person[83]["�������ֵ"] = 600
  JY.Person[83]["����"] = 3500
  JY.Person[83]["�������ֵ"] = 3500
  JY.Person[83]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--����������
PNLBD[142] = function()
	JY.Person[80]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��а����ͩ
PNLBD[140] = function()
	JY.Person[74]["����"] = 500
	JY.Person[74]["�������ֵ"] = 500
	JY.Person[74]["����"] = 1500
	JY.Person[74]["�������ֵ"] = 1500
	JY.Person[74]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--ԧа���л�
PNLBD[132] = function()
	JY.Person[77]["����"] = 500
	JY.Person[77]["�������ֵ"] = 500
	JY.Person[77]["����"] = 1500
	JY.Person[77]["�������ֵ"] = 1500
	JY.Person[77]["�书�ȼ�1"] = 999
	JY.Person[77]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--��֮��Ů��ս����˫��
PNLBD[280] = function()
	--���˷�
	JY.Person[3]["�书2"] = 67
	JY.Person[3]["�书�ȼ�2"] = 999
	JY.Person[3]["Я����Ʒ1"] = -1
	JY.Person[3]["Я����Ʒ2"] = -1
	JY.Person[3]["Я����Ʒ3"] = -1
	JY.Person[3]["Я����Ʒ����1"] = 0
	JY.Person[3]["Я����Ʒ����2"] = 0
	JY.Person[3]["Я����Ʒ����3"] = 0
end

--��аһ�ƾ�
PNLBD[68] = function()
	--����
	JY.Person[55]["����"] = 800
	JY.Person[55]["�������ֵ"] = 800
	--����
	JY.Person[56]["����"] = 700
	JY.Person[56]["�������ֵ"] = 700
	JY.Person[56]["����"] = 3000
	JY.Person[56]["�������ֵ"] = 3000
	JY.Person[56]["Я����Ʒ1"] = -1
	JY.Person[56]["Я����Ʒ2"] = -1
	JY.Person[56]["Я����Ʒ3"] = -1
	JY.Person[56]["Я����Ʒ����1"] = 0
	JY.Person[56]["Я����Ʒ����2"] = 0
	JY.Person[56]["Я����Ʒ����3"] = 0
	JY.Person[56]["Ѫ������"] = JY.Person[592]["Ѫ������"]
end

--�������������
PNLBD[275] = function()
	JY.Person[62]["�书3"] = 169
	JY.Person[62]["�书�ȼ�3"] = 999
	JY.Person[62]["�츳�ڹ�"] = 169
end

--ս�Ĵ�ɽ
PNLBD[290] = function()
	--Զ�����
	JY.Person[190]["����"] = "Զ�����"
	JY.Person[190]["����"] = 999
	JY.Person[190]["�������ֵ"] = 999
	JY.Person[190]["����"] = 7000
	JY.Person[190]["�������ֵ"] = 7000
	JY.Person[190]["��������"] = 2
	JY.Person[190]["������"] = 200
	JY.Person[190]["������"] = 200
	JY.Person[190]["�Ṧ"] = 150
	JY.Person[190]["�书1"] = 22
	JY.Person[190]["�书�ȼ�1"] = 999
	JY.Person[190]["�书2"] = 108
	JY.Person[190]["�书�ȼ�2"] = 999
	JY.Person[190]["�书3"] = 145
	JY.Person[190]["�书�ȼ�3"] = 999
	JY.Person[190]["�书4"] = 96
	JY.Person[190]["�书�ȼ�4"] = 999
	JY.Person[190]["�书5"] = 144
	JY.Person[190]["�书�ȼ�5"] = 999
	JY.Person[190]["�츳�⹦1"] = 22
	JY.Person[190]["�츳�ڹ�"] = 108
	JY.Person[190]["�츳�Ṧ"] = 145
	--����ѩ��
	JY.Person[429]["����"] = "����ѩ��"
	JY.Person[429]["����"] = 999
	JY.Person[429]["�������ֵ"] = 999
	JY.Person[429]["����"] = 9999
	JY.Person[429]["�������ֵ"] = 9999
	JY.Person[429]["��������"] = 0
	JY.Person[429]["������"] = 300
	JY.Person[429]["������"] = 150
	JY.Person[429]["�Ṧ"] = 100
	JY.Person[429]["�书1"] = 156
	JY.Person[429]["�书�ȼ�1"] = 999
	JY.Person[429]["�书2"] = 107
	JY.Person[429]["�书�ȼ�2"] = 999
	JY.Person[429]["�书3"] = 148
	JY.Person[429]["�书�ȼ�3"] = 999
	JY.Person[429]["�书4"] = 87
	JY.Person[429]["�书�ȼ�4"] = 999
	JY.Person[429]["�书5"] = 92
	JY.Person[429]["�书�ȼ�5"] = 999
	JY.Person[429]["�츳�⹦1"] = 156
	JY.Person[429]["�츳�ڹ�"] = 107
	JY.Person[429]["�츳�Ṧ"] = 148
	--֩������
	JY.Person[439]["����"] = "֩������"
	JY.Person[439]["����"] = 999
	JY.Person[439]["�������ֵ"] = 999
	JY.Person[439]["����"] = 8500
	JY.Person[439]["�������ֵ"] = 8500
	JY.Person[439]["��������"] = 1
	JY.Person[439]["������"] = 150
	JY.Person[439]["������"] = 300
	JY.Person[439]["�Ṧ"] = 100
	JY.Person[439]["�书1"] = 66
	JY.Person[439]["�书�ȼ�1"] = 999
	JY.Person[439]["�书2"] = 106
	JY.Person[439]["�书�ȼ�2"] = 999
	JY.Person[439]["�书3"] = 147
	JY.Person[439]["�书�ȼ�3"] = 999
	JY.Person[439]["�书4"] = 169
	JY.Person[439]["�书�ȼ�4"] = 999
	JY.Person[439]["�书5"] = 94
	JY.Person[439]["�书�ȼ�5"] = 999
	JY.Person[439]["�츳�⹦1"] = 66
	JY.Person[439]["�츳�ڹ�"] = 106
	JY.Person[439]["�츳�Ṧ"] = 147
end

--��ħ����
PNLBD[291] = function()
	--����
	JY.Person[604]["����"] = 9999
	JY.Person[604]["�������ֵ"] = 9999
	JY.Person[604]["������"] = 300
	JY.Person[604]["�Ṧ"] = 400
	JY.Person[604]["��������"] = 320
end

--��ʮ��
PNLBD[289] = function()
	--������
	JY.Person[129]["�书2"] = 107
	JY.Person[129]["�츳�ڹ�"] = 107
	JY.Person[129]["�츳�Ṧ"] = 148
	JY.Person[129]["��������"] = 0
	--��ҩʦ
	JY.Person[57]["�书2"] = 107
	JY.Person[57]["�书�ȼ�2"] = 999
	JY.Person[57]["�츳�ڹ�"] = 107
	JY.Person[57]["�书3"] = 12
	JY.Person[57]["�书�ȼ�3"] = 999
	JY.Person[57]["�书4"] = 38
	JY.Person[57]["�书�ȼ�4"] = 999
	JY.Person[57]["����"] = 5000
	JY.Person[57]["�������ֵ"] = 5000
	JY.Person[57]["��������"] = 0
	--ŷ����
	JY.Person[60]["�书3"] = 81
	JY.Person[60]["�书�ȼ�3"] = 999
	JY.Person[60]["�书4"] = 107
	JY.Person[60]["�书�ȼ�4"] = 999
	JY.Person[60]["����"] = 5000
	JY.Person[60]["�������ֵ"] = 5000
	JY.Person[60]["��������"] = 0
	--һ��
	JY.Person[65]["�츳�ڹ�"] = 107
	JY.Person[65]["�书3"] = 107
	JY.Person[65]["�书�ȼ�3"] = 999
	JY.Person[65]["����"] = 5000
	JY.Person[65]["�������ֵ"] = 5000
	JY.Person[65]["��������"] = 0
	--���߹�
	JY.Person[69]["�츳�ڹ�"] = 107
	JY.Person[69]["�书3"] = 107
	JY.Person[69]["�书�ȼ�3"] = 999
	JY.Person[69]["����"] = 5000
	JY.Person[69]["�������ֵ"] = 5000
	JY.Person[69]["��������"] = 0
	--�ܲ�ͨ
	JY.Person[64]["�书�ȼ�2"] = 999
	JY.Person[64]["��������"] = 0
	JY.Person[64]["�书3"] = 16
	JY.Person[64]["�书�ȼ�3"] = 999
	--������
	JY.Person[140]["�书3"] = 108
	JY.Person[140]["�书�ȼ�3"] = 999
	JY.Person[140]["�츳�ڹ�"] = 108
	--����
	JY.Person[62]["�书3"] = 169
	JY.Person[62]["�书�ȼ�3"] = 999
	JY.Person[62]["�츳�ڹ�"] = 169
	JY.Person[62]["����"] = 5000
	JY.Person[62]["�������ֵ"] = 5000
	--������
	JY.Person[5]["����"] = 7000
	JY.Person[5]["�������ֵ"] = 7000
	--Ľ�ݲ�
	JY.Person[113]["������"] = 150
	JY.Person[113]["������"] = 150
	JY.Person[113]["�书3"] = 108
	JY.Person[113]["�书�ȼ�3"] = 999
	JY.Person[113]["�츳�ڹ�"] = 108
	--��Զɽ
	JY.Person[112]["�书3"] = 108
	JY.Person[112]["�书�ȼ�3"] = 999
	JY.Person[112]["�츳�ڹ�"] = 108
	JY.Person[112]["����"] = 6000
	JY.Person[112]["�������ֵ"] = 6000
	--�Ħ��
	JY.Person[103]["�书3"] = 108
	JY.Person[103]["�书�ȼ�3"] = 999
	JY.Person[103]["�츳�ڹ�"] = 108
	JY.Person[103]["����"] = 6000
	JY.Person[103]["�������ֵ"] = 6000
	JY.Person[103]["����"] = 900
	JY.Person[103]["�������ֵ"] = 900
	--�Ƿ�
	JY.Person[50]["�书3"] = 108
	JY.Person[50]["�书�ȼ�3"] = 999
	JY.Person[50]["�츳�ڹ�"] = 108
	JY.Person[50]["�츳�Ṧ"] = 145
	--ɨ����ɮ
	JY.Person[114]["�书2"] = 106
	JY.Person[114]["�书�ȼ�2"] = 999
	JY.Person[114]["�书3"] = 107
	JY.Person[114]["�书�ȼ�3"] = 999
end

--Ц��
PNLBD[297] = function()
	--������
	JY.Person[22]["����"] = 800
	JY.Person[22]["�������ֵ"] = 800
	JY.Person[22]["�书2"] = 30
	JY.Person[22]["�书�ȼ�2"] = 999
	JY.Person[22]["�书3"] = 31
	JY.Person[22]["�书�ȼ�3"] = 999
	JY.Person[22]["�书4"] = 32
	JY.Person[22]["�书�ȼ�4"] = 999
	JY.Person[22]["�书5"] = 34
	JY.Person[22]["�书�ȼ�5"] = 999
	JY.Person[22]["�书6"] = 175
	JY.Person[22]["�书�ȼ�6"] = 900
	--��ƽ֮
	JY.Person[36]["����"] = 700
	JY.Person[36]["�������ֵ"] = 700
	JY.Person[36]["����"] = 4800
	JY.Person[36]["�������ֵ"] = 4800
	JY.Person[36]["�书�ȼ�1"] = 999
end

--��������Ⱥ
PNLBD[298] = function()
	JY.Person[19]["����"] = 900
	JY.Person[19]["�������ֵ"] = 900
	JY.Person[19]["������"] = 250
	JY.Person[19]["������"] = 250
	JY.Person[19]["�Ṧ"] = 270
	JY.Person[19]["�츳�ڹ�"] = 105
	JY.Person[19]["�书3"] = 175
	JY.Person[19]["�书�ȼ�3"] = 900
end

--ս����ʼ������������
function WarFixBack()
	for j = 0, WAR.PersonNum - 1 do
		local i = War_AutoSelectEnemy_near(j)
		--lib.Debug(j.."start"..i)
		if i >= 0 then
			WAR.Person[j]["�˷���"] = War_Direct(WAR.Person[j]["����X"], WAR.Person[j]["����Y"],
				WAR.Person[i]["����X"], WAR.Person[i]["����Y"])
			--WAR.Person[j]["��ͼ"] = WarCalPersonPic(j)
		end
	end
end

--���أ����Ŷݼ�
function WarNewLand0()
	local baguax = 0
	local baguay = 0
	local lives = 0
	for j = 0, WAR.PersonNum - 1 do
		if not WAR.Person[j]["����"] then
			baguax = baguax + WAR.Person[j]["����X"]
			baguay = baguay + WAR.Person[j]["����Y"]
			lives = lives + 1
		end
	end
	baguax = math.modf(baguax / lives)
	baguay = math.modf(baguay / lives)
	WarNewLand(baguax, baguay)
end

function WarNewLand(x, y)
	--1��ɫ��2��ɫ��3��ɫ��4��ɫ
	CleanWarMap(6,-1);

	--����Χ��������
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
	SetWarMap(x + math.random(-4, 4), y + math.random(-4, 4), 6, math.random(2, 3));
end

--ս��������
function WarMain(warid, isexp)
	WarLoad(warid)			--��ʼ��ս������
	JY.SubScene = WAR.Data["��ͼ"]
	WarSelectTeam_Enhance()	--ѡ���ҷ����Ż��棩
	WarSelectEnemy()		--ѡ�����

	Health_in_Battle()		--�޾Ʋ�����Ѫ������

	if JY.Restart == 1 then
		return false
	end

	CleanMemory()
	lib.PicInit()
	lib.ShowSlow(20, 1)
	WarLoadMap(WAR.Data["��ͼ"])	--����ս����ͼ

	--Ĭ���ڵ�ǰ����ս��
	local BattleField = JY.SubScene

	--���������þ���ս��
	if WAR.ZDDH == 287 then
		BattleField = 116
	end

	for i = 0, CC.WarWidth-1 do
		for j = 0, CC.WarHeight-1 do
			lib.SetWarMap(i, j, 0, lib.GetS(BattleField, i, j, 0))
			lib.SetWarMap(i, j, 1, lib.GetS(BattleField, i, j, 1))
		end
	end

	--ѩɽ�仨��ˮս��
	if WAR.ZDDH == 42 then
		SetS(2, 24, 31, 1, 0)
		SetS(2, 30, 34, 1, 0)
		SetS(2, 27, 27, 1, 0)
	end

	--�ɰ滪ɽ�۽�����̨
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

	--20����֣���������
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

	--ս�Ĵ�ɽ����������
	if WAR.ZDDH == 290 then
		for i = 5, 34 do
			lib.SetWarMap(7, i, 1, 0)
			lib.SetWarMap(9, i, 1, 0)
			lib.SetWarMap(54, i, 1, 0)
			lib.SetWarMap(56, i, 1, 0)
		end
	end

	--ɱ��������
	if WAR.ZDDH == 54 then
		lib.SetWarMap(11, 36, 1, 2)
	end

	--�ı���Ϸ״̬
	JY.Status = GAME_WMAP

	--������ͼ�ļ�
	lib.PicLoadFile(CC.WMAPPicFile[1], CC.WMAPPicFile[2], 0)						--ս����ͼ���ڴ�����0

	lib.LoadPNGPath(CC.HeadPath, 1, CC.HeadNum, limitX(CC.ScreenW/936*100,0,100))	--�����ͷ���ڴ�����1

	lib.PicLoadFile(CC.ThingPicFile[1], CC.ThingPicFile[2], 2, 100, 100)			--��Ʒ��ͼ���ڴ�����2

	lib.PicLoadFile(CC.EFTFile[1], CC.EFTFile[2], 3)								--��Ч��ͼ���ڴ�����3

	lib.LoadPNGPath(CC.IconPath, 98, CC.IconNum, limitX(CC.ScreenW/936*100,0,100))	--״̬ͼ�꣬�ڴ�����98

	lib.LoadPNGPath(CC.HeadPath, 99, CC.HeadNum, 26.923076923)						--����Сͷ�����ڼ��������ڴ�����99

	--�޾Ʋ��������ս������
	local zdyy = math.random(10) + 99

	--15��̶�
	if WAR.ZDDH == 133 or WAR.ZDDH == 134 then
		zdyy = 27
	end

	--VS������ɮս�̶�
	if WAR.ZDDH == 80 then
		zdyy = 22
	end

	--��������ս�̶�
	if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 then
		zdyy = 112
	end

	--�ɸ�ս�̶�
	if WAR.ZDDH == 278 then
		zdyy = 110
	end

	--�䵱ս����̶�
	if WAR.ZDDH == 22 then
		zdyy = 113
	end

	--20�����ս�̶�
	if WAR.ZDDH == 289 then
		zdyy = 115
	end

	--ս�Ĵ�ɽ�̶�
	if WAR.ZDDH == 290 then
		zdyy = 117
	end

	--��ħ���ɹ̶�
	if WAR.ZDDH == 291 then
		zdyy = 118
	end

	PlayMIDI(zdyy)

	--PlayMIDI(WAR.Data["����"])  

	local warStatus = nil		 --ս��״̬

	WarPersonSort()			--���Ṧ����
	CleanWarMap(2, -1)
	CleanWarMap(6, -2)


	for i = 0, WAR.PersonNum - 1 do

		if i == 0 then
		  WAR.Person[i]["����X"], WAR.Person[i]["����Y"] = WE_xy(WAR.Person[i]["����X"], WAR.Person[i]["����Y"])
		else
		  WAR.Person[i]["����X"], WAR.Person[i]["����Y"] = WE_xy(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], i)
		end

		SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 2, i)

		local pid = WAR.Person[i]["������"]
		lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[pid]["ͷ�����"]), string.format(CC.FightPicFile[2], JY.Person[pid]["ͷ�����"]), 4 + i)	--����ս��������ͼ���ڴ�����4-29��һ��ս������26�ˣ�

		--Alungky ��5000����������ͷ������
		--���ǵ�����Ҫ���⴦��
		if pid == 0 and JY.Base["����"] == 0 then
			if JY.Base["��׼"] > 0 then
				if JY.Person[0]["�Ա�"] == 0 then
					WAR.tmp[5000+i] = 280 + JY.Base["��׼"]
				else
					WAR.tmp[5000+i] = 500 + JY.Base["��׼"]
				end
			--����
			else
				if JY.Person[0]["�Ա�"] == 0 then
					WAR.tmp[5000+i] = 290
				else
					WAR.tmp[5000+i] = 368
				end
			end
		else
			WAR.tmp[5000+i] = JY.Person[pid]["ͷ�����"]
		end
	end

	--�Ṧ���ƶ����ӵļ���
	local function getnewmove(id)
		local mov = JY.Person[WAR.Person[id]["������"]]["��������"]
		--��׺��������
		if WAR.Person[id]["������"] == 24 then
			for j = 0, WAR.PersonNum - 1 do
				if id ~= j and WAR.Person[j]["�ҷ�"] == true and JY.Person[WAR.Person[j]["������"]]["����"] > 0 then
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
		WAR.Person[i]["��ͼ"] = WarCalPersonPic(i)
	end
	WarSetPerson()
	WAR.CurID = 0
	WarDrawMap(0)
	lib.ShowSlow(20, 0)

	--�޾Ʋ�������������ĳ�ʼ����λ��
	for i = 0, WAR.PersonNum - 1 do
		WAR.Person[i].Time = 800 - i * 1000 / WAR.PersonNum

		--����ɺ ÿ������+50���ʼ����
		if match_ID(WAR.Person[i]["������"], 79) then
			local JF = 0
			local bh = WAR.Person[i]["������"]
			for i = 1, CC.Kungfunum do
				if JY.Wugong[JY.Person[bh]["�书" .. i]]["�书����"] == 3 then
					JF = JF + 1
				end
			end
			WAR.Person[i].Time = WAR.Person[i].Time + (JF) * 50
		end

		if WAR.Person[i].Time > 990 then
			WAR.Person[i].Time = 990
		end

		--����壬һ��֮�󣬳�ʼ������
		if match_ID_awakened(WAR.Person[i]["������"], 35, 1) then
			WAR.Person[i].Time = 998
		end

		--������ܣ���ʼ������
		if match_ID(WAR.Person[i]["������"], 592) then
			WAR.Person[i].Time = 999
		end

		--Ѫ������ ��ʼ����900
		if match_ID(WAR.Person[i]["������"], 97) then
			WAR.Person[i].Time = 900
		end

		--̫���ʼ����-200
		if JY.Person[WAR.Person[i]["������"]]["�Ա�"] == 2 then
			WAR.Person[i].Time = -200
		end

		--��ƽ֮ ��ʼ����900
		if match_ID(WAR.Person[i]["������"], 36) then
			WAR.Person[i].Time = 900
		end

		--ľ׮�ĳ�ʼ����
		if WAR.Person[i]["������"] == 591 and WAR.ZDDH == 226 then
			WAR.Person[i].Time = 0
		end

		--ʥ���� ��ʼ������200��100���
		local id = WAR.Person[i]["������"]
		if PersonKF(id, 93) then
			WAR.Person[i].Time = WAR.Person[i].Time + 200 + math.random(100)
		end
		if WAR.Person[i].Time > 990 then
			WAR.Person[i].Time = 990
		end

		--�۽���Ӯ�����ά������������
		if WAR.Person[i]["������"] == 0 and JY.Person[606]["�۽�����"] == 1 then
			for j = 0, WAR.PersonNum - 1 do
				WAR.Person[j].Time = WAR.Person[j].Time - 75
				if WAR.Person[j].Time > 990 then
					WAR.Person[j].Time = 990
				end
			end
			WAR.Person[i].Time = 1005
		end

		--�ƶ������ڴ�
		WAR.Person[i]["�ƶ�����"] = getnewmove(i)
		
		--[[if WAR.Person[i]["�ƶ�����"] < 1 then
			WAR.Person[i]["�ƶ�����"] = 1
		end]]
	end

	--Я����Ʒ�ĳ�ʼ��
	for a = 0, WAR.PersonNum - 1 do
		for s = 1, 4 do
			if JY.Person[WAR.Person[a]["������"]]["Я����Ʒ����" .. s] == nil or JY.Person[WAR.Person[a]["������"]]["Я����Ʒ����" .. s] < 1 then
				JY.Person[WAR.Person[a]["������"]]["Я����Ʒ" .. s] = -1
				JY.Person[WAR.Person[a]["������"]]["Я����Ʒ����" .. s] = 0;
			end
		end
	end

	--Ц��а�ߣ���ľ����������������ܣ��򶫷����Կ���������̬��ս
	if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 then
		local dfid;
		for i = 0, WAR.PersonNum - 1 do
			local id = WAR.Person[i]["������"]
			if id == 27 then
				dfid = i;
				break
			end
		end
		local orid = WAR.CurID
		WAR.CurID = dfid

		Cls()
		local KHZZ = {"��Ա���","�Է����ҵ�����ս","������"}

		for i = 1, #KHZZ do
			lib.GetKey()
			DrawString(-1, -1, KHZZ[i], C_GOLD, CC.Fontsmall)
			ShowScreen()
			Cls()
			lib.Delay(1000)
		end

		CurIDTXDH(WAR.CurID, 7, 1)

		lib.Background(0,200,CC.ScreenW,400,78)
		NewDrawString(CC.ScreenW, CC.ScreenH/2 + 160, "������������̬", C_GOLD, 80)
		NewDrawString(CC.ScreenW, CC.ScreenH/2 + 360, "���� �����ڳ���ȼ��", C_RED, 70)

		ShowScreen()
		Cls()
		lib.Delay(2000)

		local KHZZ2 = {"��֪�����"..JY.Person[0]["���2"],"�ú�����һ�������Ŀֲ���"}

		for i = 1, #KHZZ2 do
			lib.GetKey()
			DrawString(-1, -1, KHZZ2[i], C_GOLD, CC.Fontsmall)
			ShowScreen()
			Cls()
			lib.Delay(1000)
		end

		WAR.CurID = orid
	end

	--ʥ����ʹս���ֵ�������Ч
	if WAR.ZDDH == 14 then
		say("�ǣ����ʹ��", 173, 0)   --���ʹ
		say("�ǣ�����ʹ��", 174, 1)   --����ʹ
		say("�ǣ�����ʹ����ʥ��������", 175, 5)   --����ʹ����ʥ��������
		for i = 15, 35 do
			lib.GetKey()
			NewDrawString(-1, -1, "ʥ��������", C_GOLD, CC.DefaultFont+i*2)
			ShowScreen()
			Cls()
			if i == 35 then
				lib.Delay(500)
			else
				lib.Delay(5)
			end
		end
	end

	--�ܵ�����ս���ҷ�����ȫ��Ϊ0
	if WAR.ZDDH == 237 then
		for a = 0, WAR.PersonNum - 1 do
			if WAR.Person[a]["�ҷ�"] == true then
				WAR.Person[a].Time = 0
			end
		end
	end

	--ȫ�����ӣ��������
	if WAR.ZDDH == 73 then
		for i = 15, 35 do
			lib.GetKey()
			NewDrawString(-1, -1, "�������", C_GOLD, CC.DefaultFont+i*2)
			ShowScreen()
			Cls()
			if i == 35 then
				lib.Delay(500)
			else
				lib.Delay(5)
			end
		end
	end

	--��϶�����ʾ
	if CC.CoupleDisplay == 1 then
		local function fightcombo()
			local combo = {}
			for i = 1, #CC.COMBO do
				combo[i] = {CC.COMBO[i][1], CC.COMBO[i][2], CC.COMBO[i][3],0}
			end
			for i = 0, WAR.PersonNum - 1 do
				local t = WAR.Person[i]["������"]
				for j = 1, #combo do
					lib.GetKey()
					if match_ID(t, combo[j][1]) then
						for z = 0, WAR.PersonNum - 1 do
							local t2 = WAR.Person[z]["������"]
							if match_ID(t2, combo[j][2]) and WAR.Person[i]["�ҷ�"] == WAR.Person[z]["�ҷ�"] then
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
						local str = JY.Person[t1]["����"].."��"..JY.Person[t2]["����"]
						local str2 = combo[i][3]
						Cls()
						DrawBox(150, CC.ScreenH / 3 + 30, CC.ScreenW - 150, CC.ScreenH / 3 * 2 - 20, C_BLACK)
						lib.LoadPNG(1, JY.Person[t1]["ͷ�����"]*2, CC.ScreenW / 4 - 80, CC.ScreenH / 2 - 35, 1)
						lib.LoadPNG(1, JY.Person[t2]["ͷ�����"]*2, CC.ScreenW / 4 + 50, CC.ScreenH / 2 - 35, 1)
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

	--�İ���֮ս���Ƿ�������
	if WAR.ZDDH == 83 then
		JY.Person[50]["�书1"] = 13
    end

	warStatus = 0
	buzhen()
	--Pre_Yungong()	--�޾Ʋ�����սǰ�˹�

	--�������Ŷݼ��ڴ�
	WarNewLand0()
	--WarFixBack()

	WAR.Delay = GetJiqi()
	local startt, endt = lib.GetTime()

  --ս����ѭ��
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

		if WAR.Person[p]["����"] == false and WAR.Person[p].Time > 1000 then


        WarDrawMap(0)
        ShowScreen()
        local keypress = lib.GetKey()
        if WAR.AutoFight == 1 and (keypress == VK_SPACE or keypress == VK_RETURN) then
			WAR.AutoFight = 0
        end
        reget = true
        local id = WAR.Person[p]["������"]


        --���Ҵ���֮�󣬲����ƶ�
        if WAR.ZYHB == 2 then
			WAR.Person[p]["�ƶ�����"] = 0
		--��Ч�������ƶ�
        elseif WAR.L_NOT_MOVE[WAR.Person[p]["������"]] ~= nil and WAR.L_NOT_MOVE[WAR.Person[p]["������"]] == 1 then
        	WAR.Person[p]["�ƶ�����"] = 0
        	WAR.L_NOT_MOVE[WAR.Person[p]["������"]] = nil
        else
        	--�����ƶ�����
			WAR.Person[p]["�ƶ�����"] = getnewmove(p)
        end

        --[[����ƶ�����10
        if WAR.Person[p]["�ƶ�����"] > 10 then
			WAR.Person[p]["�ƶ�����"] = 10
        end]]

        WAR.ShowHead = 0
        WarDrawMap(0)
        WAR.Effect = 0
        WAR.CurID = p
        WAR.Person[p].TimeAdd = 0
        local r = nil
        local pid = WAR.Person[WAR.CurID]["������"]
        WAR.Defup[pid] = nil

		--������ָ��ж�ǰ�ָ�
        if match_ID(pid, 53) then
			WAR.TZ_DY = 0
        end

		--Ľ�ݸ���ָ��ж�ǰ�ָ�
        if match_ID(pid, 51) then
			WAR.TZ_MRF = 0
        end

		--���û��ذ���λ��
		if GetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 6) > 0 then
			WarNewLand0()
		end

		--���࣬�ж�ǰ�����ж���0
	    if match_ID(pid, 604) then
			JY.Person[pid]["���˳̶�"] = 0
			JY.Person[pid]["�ж��̶�"] = 0
	    end

		--���ţ��ж���ʼǰ��60%���ʽ��͵з�����100��
		if match_ID(pid, 629) and JLSD(20,80,pid) then
			for j = 0, WAR.PersonNum - 1 do
				if WAR.Person[j]["����"] == false and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
					WAR.Person[j].TimeAdd = WAR.Person[j].TimeAdd - 100
				end
			end
			DrawTimeBar2()
		end

		--�����Ϣ��60%������Ϣ
		if Curr_NG(pid, 100) and math.random(10) < 7 then
			WarDrawMap(0); --���������򶯻�λ���޷�������ʾ
			CurIDTXDH(WAR.CurID, 19,1,"�����Ϣ",C_ORANGE);
			WAR.XTTX = 1
			War_RestMenu()
			WAR.XTTX = 0
		end

		--ս����ʱ������100ʱ����������������
		if WAR.ZDDH == 253 and match_ID(pid, 631) and WAR.ZZRZY == 0 and 100 < WAR.SXTJ then
			say("���̣�������������ͨ���繥��һ�ˣ����������������ػ�����������ܹ����󣿣��������ܷ��Ķ��ã�ͬʱ�������������������Ӧ�ԣ���", 357, 0,"������")  --�Ի�
			if JY.Base["����"] == 631 then
				JY.Person[0]["���һ���"] = 1
			else
				JY.Person[631]["���һ���"] = 1
			end
			WAR.ZZRZY = 1
		end

		--����״̬���ж�ǰ�������
		--ֻʣһ������ʱ����������
		if WAR.HLZT[pid] ~= nil then
			local EmenyNum = 0
			for i = 0, WAR.PersonNum - 1 do
				if WAR.Person[i]["����"] == false and WAR.Person[i]["�ҷ�"] == false then
					EmenyNum = EmenyNum + 1
				end
			end
			if EmenyNum > 1 then
				if math.random(2) == 1 then
					WAR.Person[p]["�ҷ�"] = true
				else
					WAR.Person[p]["�ҷ�"] = false
				end
			end
		end

		--�ж�ʱ��ʾѪ��
		WAR.ShowHP = 1

		--�޾Ʋ������ж�ʱ����ȡָ��
		if WAR.HMZT[pid] ~= nil then			--����״̬
			WarDrawMap(0); --���������򶯻�λ���޷�������ʾ
			CurIDTXDH(WAR.CurID, 94,1,"������",C_ORANGE)
			WAR.HMZT[pid] = nil
        elseif inteam(pid) and WAR.Person[p]["�ҷ�"] then
			if WAR.AutoFight == 0 then
				r = War_Manual()
			elseif JY.Person[pid]["�����Զ�"] == 1 then
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


        --����������һ���
        if WAR.ZYHB == 1 then
			for j = 0, WAR.PersonNum - 1 do
				WAR.Person[j].Time = WAR.Person[j].Time - 15
				if WAR.Person[j].Time > 990 then
					WAR.Person[j].Time = 990
				end
			end
			WAR.Person[p].Time = 1005
			if WAR.ZHB == 0 then	--�ܲ�ͨ�Ķ����������ﲻ���ظ���¼
				WAR.ZYYD = WAR.Person[p]["�ƶ�����"]
			end
			WAR.ZYHBP = p

	        --һ�ƣ����ⱻ����
	        if JY.Person[65]["����"] <= 0 and WAR.WCY[65] == nil then
				JY.Person[65]["����"] = 1
	        end

	        if JY.Base["����"] == 65 and JY.Person[0]["����"] <= 0 and WAR.WCY[0] == nil then
				JY.Person[0]["����"] = 1
	        end

			--������
			if JY.Person[129]["����"] <= 0 and WAR.CYZX[129] == nil then
				JY.Person[129]["����"] = 1
			end

	        if JY.Base["����"] == 129 and JY.Person[0]["����"] <= 0 and WAR.CYZX[0] == nil then
				JY.Person[0]["����"] = 1
	        end

			--�ֻ�͵Ǯ
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

			--�޺���ħ�� ÿ�غϻظ�����
			if PersonKF(id, 96) and JY.Person[id]["����"] > 0 then
				local heal_amount;
				heal_amount = (JY.Person[id]["�������ֵ"] - JY.Person[id]["����"])/JY.Person[pid]["Ѫ������"]
				if Curr_NG(id, 96) then
					heal_amount = math.modf(heal_amount * 0.2)
				else
					heal_amount = math.modf(heal_amount * 0.1)
				end
				WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(id, "����", heal_amount);
				Cls();
				War_Show_Count(WAR.CurID, "�޺���ħ���ָ�����");
			end
			--�غϽ���������������
			if inteam(id) then
				JY.Person[id]["����"] = math.max(JY.Person[id]["����"] - 1, 0)
			end
			NeiLiDamage(id, 100 - JY.Person[id]["����"])

			if GetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 6) == 3 then
				local heal_amount = math.modf((JY.Person[id]["�������ֵ"] - JY.Person[id]["����"]) * 0.16)
				WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(id, "����", heal_amount);
				Cls();
				War_Show_Count(WAR.CurID, "������λ��Ѫ�ظ�");
			end

			local NS = 5
			WAR.Person[WAR.CurID]["���˵���"] = (WAR.Person[WAR.CurID]["���˵���"] or 0) + AddPersonAttrib(id, "���˳̶�", -NS)
			Cls();
			War_Show_Count(WAR.CurID, "���˻ָ�");

	        --��ϼ���ж��󣬻ظ�����
			if PersonKF(id, 89) then
				local HN;
				if Curr_NG(id, 89) then
					HN = math.modf((JY.Person[id]["�������ֵ"] - JY.Person[id]["����"])*0.2)
				else
					HN = math.modf((JY.Person[id]["�������ֵ"] - JY.Person[id]["����"])*0.1)
				end
				WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(id, "����", HN);
				Cls();
				War_Show_Count(WAR.CurID, "��ϼ�񹦻ظ�����");
			end

	        --��Ƥ���� ÿ�غϽⶾ
			if JY.Person[id]["����"] == 61 and JY.Person[id]["�ж��̶�"] > 0 then
				local JD = 25 + 10 * (JY.Thing[61]["װ���ȼ�"]-1)
				if JY.Person[id]["�ж��̶�"] < JD then
					JD = JY.Person[id]["�ж��̶�"]
				end
				WAR.Person[WAR.CurID]["�ⶾ����"] = -AddPersonAttrib(id, "�ж��̶�", -JD)
				Cls();
				War_Show_Count(WAR.CurID, "��Ƥ���������ⶾ");
			end

			--�������
			if WAR.HMGXL[id] == 1 then
				WAR.HMGXL[id] = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 300
			end

			--��ƽ֮�����˺�����
			if match_ID_awakened(id, 36, 1) and WAR.LPZ > 0 then
				WAR.Person[p].Time = WAR.Person[p].Time + WAR.LPZ
				WAR.LPZ = 0
			end

			--������ӻ�
	        if match_ID(id, 49) and WAR.XZZ == 1 then
				WAR.XZZ = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 200
	        end

			--����������Ȼ
	        if match_ID(id, 5) and WAR.ZSF == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.ZSF = 0
	        end

			--�ⲻƽ���콣
			if match_ID(id, 142) and WAR.KFKJ == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 100
				WAR.KFKJ = 0
			end

			--�Ž��洫������ʽ������200
			if WAR.JJDJ == 1 and id == 0 then
				WAR.JJDJ = 0
				WAR.Person[p].Time = WAR.Person[p].Time + 200
			end

			--���˷������200
			if Curr_QG(id,145) then
				WAR.Person[p].Time = WAR.Person[p].Time + 200
			end

			--���Ṧ
			if WAR.YQG == 1 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.YQG = 0
			end

	        --����棬����õ�ʳ��
	        if match_ID(id, 81) and WAR.ZJZ == 0 and math.random(100)>60 then
				instruct_2(210, 10)
				WAR.ZJZ = 1
	        end

	        --һ�ƣ����ⱻ����
	        if JY.Person[65]["����"] <= 0 and WAR.WCY[65] == nil then
				JY.Person[65]["����"] = 1
	        end

	        if JY.Base["����"] == 65 and JY.Person[0]["����"] <= 0 and WAR.WCY[0] == nil then
				JY.Person[0]["����"] = 1
	        end

			--������
			if JY.Person[129]["����"] <= 0 and WAR.CYZX[129] == nil then
				JY.Person[129]["����"] = 1
			end

	        if JY.Base["����"] == 129 and JY.Person[0]["����"] <= 0 and WAR.CYZX[0] == nil then
				JY.Person[0]["����"] = 1
	        end

	        --���ǣ��伲��磬����500
	        if WAR.FLHS1 == 1 and id == 0 then
				WAR.Person[p].Time = WAR.Person[p].Time + 500
				WAR.FLHS1 = 0
	        end

	        --������ж�������ʼλ�ö�������
	        --�����ٹ�����֮һʱÿ��100�����ж�����λ�ü�100
	        if match_ID(id, 58) and JY.Person[id]["����"] < JY.Person[id]["�������ֵ"]/2 then
	        	WAR.Person[p].Time = WAR.Person[p].Time + math.floor(JY.Person[id]["�������ֵ"]/2/JY.Person[id]["Ѫ������"] - JY.Person[id]["����"]/JY.Person[id]["Ѫ������"]);
	        end

			--�ֻ�͵Ǯ
	        if WAR.YJ > 0 then
				instruct_2(174, WAR.YJ)
				WAR.YJ = 0
	        end

	        --äĿ״̬�ָ�
			--[[
	        if WAR.KHCM[pid] == 2 then
				WAR.KHCM[pid] = 0
				Cls()
				DrawStrBox(-1, -1, "äĿ״̬�ָ�", C_ORANGE, CC.DefaultFont)
				ShowScreen()
				lib.Delay(500)
	        end]]

			--��Զ��ʹ��̫��ȭ��̫�����������Զ��������״̬
			if match_ID(id, 171) and WAR.WDRX == 1 then
				War_DefupMenu()
				WAR.WDRX = 0
			end

	        if WAR.Actup[id] ~= nil then
				if WAR.ZXXS[id] ~= nil then				--��ϼ����״̬����������
					WAR.ZXXS[id] = WAR.ZXXS[id] - 1
					if WAR.ZXXS[id] == 0 then
						WAR.ZXXS[id] = nil
					end
				else
					WAR.Actup[id] = WAR.Actup[id] - 1	--�������ж�һ�μ�1
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

			--�ж���©������
			WAR.Weakspot[id] = 0

			--��а��ȴʱ��ָ�
			if WAR.BXLQ[id] then
				for i = 1, 6 do
					WAR.BXLQ[id][i] = WAR.BXLQ[id][i] - 1
					if WAR.BXLQ[id][i] < 0 then
						WAR.BXLQ[id][i] = 0
					end
				end
			end

			--�Ƿ���������ָֻ�
	        JY.Wugong[13]["����"] = "����"

	        --�ܲ�ͨ��ÿ�ж�һ�Σ�����ʱ�˺�һ+10%
	        if match_ID(id, 64) then
				WAR.ZBT = WAR.ZBT + 1
	        end

			--��������������״̬����
			if match_ID(id, 129) and WAR.CYZX[id] ~= nil and WAR.BDQS > 0 then
				WAR.BDQS = WAR.BDQS - 1
				if WAR.BDQS == 0 then
					CurIDTXDH(WAR.CurID, 126,1,"��������������",C_GOLD);
				end
			end

			--��ŭ�ָ�
	        if WAR.LQZ[id] == 100 then
				--��������������״̬�ж���ŭ����
				if not (match_ID(id, 129) and WAR.CYZX[id] ~= nil and WAR.BDQS > 0) then
					WAR.LQZ[id] = 0
				end
	        end

			--�������У��ж���ָ�ŭ��
			if id == 0 and JY.Base["��׼"] == 4 and WAR.YZHYZ > 0 then
				WAR.LQZ[id] = limitX((WAR.LQZ[id] or 0) + WAR.YZHYZ, 0, 100)
				WAR.YZHYZ = 0
				if WAR.LQZ[id] ~= nil and WAR.LQZ[id] == 100 then
					CurIDTXDH(WAR.CurID, 6, 1, "ŭ������")
				end
			end

	        --��� ��  ����~~
	        if WAR.XK == 1 then
				for j = 0, WAR.PersonNum - 1 do
					if WAR.Person[j]["������"] == 58 and 0 < JY.Person[WAR.Person[j]["������"]]["����"] and WAR.Person[j]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] then
						WAR.Person[j].Time = 980
						say("�����������������������ȣ�����������������������������������������������������������������", 58,0)
						WAR.XK = 2
					end
				end
	        end

	        --���� ��֪����
	        if WAR.FLHS5 == 1 then
				local z = WAR.CurID
				for j = 0, WAR.PersonNum - 1 do
					if WAR.Person[j]["������"] == 0 and 0 < JY.Person[0]["����"] then
						WAR.FLHS5 = 2
						WAR.CurID = j
					end
				end
				if WAR.FLHS5 == 2 and WAR.AutoFight == 0 then
					WAR.Person[WAR.CurID]["�ƶ�����"] = 6
					War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)
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

	        --ʥ���� ��������ƶ�
	        if (0 < WAR.Person[p]["�ƶ�����"] or 0 < WAR.ZYYD) and WAR.Person[p]["�ҷ�"] == true and inteam(id) and WAR.AutoFight == 0 and PersonKF(id, 93) and 0 < JY.Person[id]["����"] then
				if 0 < WAR.ZYYD then
					WAR.Person[p]["�ƶ�����"] = WAR.ZYYD
					War_CalMoveStep(p, WAR.ZYYD, 0)
				else
					War_CalMoveStep(p, WAR.Person[p]["�ƶ�����"], 0)
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

			--�޾Ʋ����������Ƿ񴥷���ʥ�����ƶ������������Ӧ������һ������������Ӱ�쵽��һ���˵�ʥ���ж�
			--�����ܲ�ͨ���Ҳ��������
			if WAR.ZHB == 0 then
				WAR.ZYYD = 0
			end

			--�ܲ�ͨ��׷�ӻ����ж�
			if WAR.ZHB == 1 then
				WAR.ZHB = 0
			end

			--������ ��������ƶ�
			if match_ID(id,606) and WAR.Person[p]["�ҷ�"] == true and WAR.AutoFight == 0 and 0 < JY.Person[id]["����"] then
				WAR.Person[p]["�ƶ�����"] = 10
				War_CalMoveStep(p, WAR.Person[p]["�ƶ�����"], 0)
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

	        --ѩɽ��ɱѪ������󣬻ָ��ҷ�����
	        if WAR.ZDDH == 7 then
				for x = 0, WAR.PersonNum - 1 do
					if WAR.Person[x]["������"] == 97 and JY.Person[97]["����"] <= 0 then
						for xx = 0, WAR.PersonNum - 1 do
							if WAR.Person[xx]["������"] ~= 97 then
								WAR.Person[xx]["�ҷ�"] = true
							end
						end
					end
				end
	        end

			--�޾Ʋ�����������
	        if WAR.ZDDH == 54 and lib.GetWarMap(11, 36, 1) == 2 and inteam(WAR.Person[p]["������"]) and WAR.Person[p]["����X"] == 12 and WAR.Person[p]["����Y"] == 36 then
				lib.SetWarMap(11, 36, 1, 5420)
				WarDrawMap(0)
				say("AA")
				say("OHMYGO", 27)
				lib.SetWarMap(11, 36, 1, 0)
	        end

			--�Ž����м��ټ���
			if WAR.JJPZ[id] == 1 then
				WAR.Person[p].Time = -200
				WAR.JJPZ[id] = nil
			end

			--̫��ж�����ټ���
			if WAR.TKJQ[id] == 1 then
				WAR.Person[p].Time = -120
				WAR.TKJQ[id] = nil
			end

			--[[�ж��������Ч������600��
	        if 600 < WAR.Person[p].Time then
				WAR.Person[p].Time = 600
	        end]]

			--�޾Ʋ�����Ԭ��־����Ѫ���磬ɱ�˺��ٶ�
	        if match_ID(id, 54) and WAR.BXCF == 1 and War_isEnd() == 0 then
				for i = 12, 24 do
					NewDrawString(-1, -1, "��Ѫ����", C_RED, 25 + i)
					ShowScreen()
					if i == 24 then
						Cls()
						NewDrawString(-1, -1, "��Ѫ����", C_RED, 25 + i)
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

	        --����Խ�߷�������Խ��
	        local pz = math.modf(JY.Person[0]["����"] / 10)
	        --����ҽ�����У�ֱ���ٴ��ж�
	        if id == 0 and JY.Base["��׼"] == 8 and JY.Person[pid]["�������"] > 0 then
	        	if 50 < JY.Person[0]["����"] then
					if WAR.HTSS == 0 and JLSD(25, 60 + pz, 0) and 0 < JY.Person[0]["�书9"] then
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
						JY.Person[0]["����"] = JY.Person[0]["����"] - 10
						--�е͸����ٴη���
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

	        --�����ܵ� 100ʱ�����
	        if WAR.ZDDH == 237 and 100 < WAR.SXTJ then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["�ҷ�"] == false then
						WAR.Person[i]["����"] = true
					end
				end
				say("���̣��ţ�û�������"..JY.Person[0]["���2"].."�����ˣ��׹�������"..JY.Person[0]["���2"].."���������ˣ��Ϸ���Ҫ�´��죬��ξͷ���һ��", 18,0)
	        end

	      	 --����������ʮ���20ʱ��ʤ��
	        if WAR.ZDDH == 134 and 20 < WAR.SXTJ and GetS(87,31,32,5) == 1 then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["�ҷ�"] == false then
						WAR.Person[i]["����"] = true
					end
				end
				TalkEx("��ϲ"..JY.Person[0]["���"].."ͦ��20ʱ�򣬳ɹ����ء�",269,0);
	        end

			--��������аʮ���20ʱ��ʤ��
	        if WAR.ZDDH == 133 and 20 < WAR.SXTJ and GetS(87,31,31,5) == 1 then
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["�ҷ�"] == false then
						WAR.Person[i]["����"] = true
					end
				end
				TalkEx("��ϲ"..JY.Person[0]["���"].."ͦ��20ʱ�򣬳ɹ����ء�",269,0);
	        end


	        --�ɰ滪ɽ�۽�����������任
	        if WAR.ZDDH == 238 then
	        	local life = 0
	        	WAR.NO1 = 114;
				for i = 0, WAR.PersonNum - 1 do
					if WAR.Person[i]["����"] == false and 0 < JY.Person[WAR.Person[i]["������"]]["����"] then
						life = life + 1
						if WAR.NO1 >= WAR.Person[i]["������"] then
							WAR.NO1 = WAR.Person[i]["������"]
						end
					end
				end

				if 1 < life then
					local m, n = 0, 0
					while true do			--��ֹȫ��������ѷ�
						if m >= 1 and n >= 1 then
							break;
						else
							m = 0;
							n = 0;
						end

						for i = 0, WAR.PersonNum - 1 do
							if WAR.Person[i]["����"] == false and 0 < JY.Person[WAR.Person[i]["������"]]["����"] then
								if WAR.Person[i]["������"] == 0 then
									WAR.Person[i]["�ҷ�"] = true
									m = m + 1
								elseif math.random(2) == 1 then
									WAR.Person[i]["�ҷ�"] = true
									m = m + 1
								else
									WAR.Person[i]["�ҷ�"] = false
									n = n + 1
								end
							end
						end
					end
				end
	        end
	    end
	end

		warStatus = War_isEnd()   --ս���Ƿ������   0������1Ӯ��2��
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

	--ս��������Ľ���
	if WAR.ZDDH == 238 then
		PlayMIDI(111)
		PlayWavAtk(41)
		DrawStrBoxWaitKey("�۽�����", C_WHITE, CC.DefaultFont)
		DrawStrBoxWaitKey("�书���µ�һ�ߣ�" .. JY.Person[WAR.NO1]["����"], C_RED, CC.DefaultFont)
		if WAR.NO1 == 0 then
		  r = true
		else
		  r = false
		end
	--ս��ʤ��
	elseif warStatus == 1 then
		PlayMIDI(111)
		PlayWavAtk(41)
		--DrawStrBoxWaitKey("ս��ʤ��", C_WHITE, CC.DefaultFont)
		lib.LoadPNG(1, 998 * 2 , 295, 295, 1)
		ShowScreen();
		WaitKey();
		if WAR.ZDDH == 76 then
			DrawStrBoxWaitKey("���⽱����ǧ����֥��ö", C_GOLD, CC.DefaultFont)
			instruct_32(14, 2)
		elseif WAR.ZDDH == 15 or WAR.ZDDH == 80 then
			DrawStrBoxWaitKey("���⽱����������ϵ����ֵ����ʮ��", C_RED, CC.DefaultFont,nil,C_GOLD)
			AddPersonAttrib(0, "ȭ�ƹ���", 10)
			AddPersonAttrib(0, "ָ������", 10)
			AddPersonAttrib(0, "��������", 10)
			AddPersonAttrib(0, "ˣ������", 10)
			AddPersonAttrib(0, "�������", 10)
		elseif WAR.ZDDH == 100 then
			DrawStrBoxWaitKey("���⽱���������������������", C_GOLD, CC.DefaultFont)
			instruct_32(8, 2)
		elseif WAR.ZDDH == 172 then
			DrawStrBoxWaitKey("���⽱������ø�󡹦�ؼ�һ��", C_GOLD, CC.DefaultFont)
			instruct_32(73, 1)
		elseif WAR.ZDDH == 173 then
			DrawStrBoxWaitKey("���⽱���������ɽѩ����ö", C_GOLD, CC.DefaultFont)
			instruct_32(17, 2)
		elseif WAR.ZDDH == 188 then
			local hqjl = JYMsgBox("���⽱��", "������˽���ս**��ѡ��һ�����ֵ�������", {"ȭ��","ָ��","����","����","����"}, 5, 69)
			if hqjl == 1 then
				AddPersonAttrib(0, "ȭ�ƹ���", 10)
				DrawStrBoxWaitKey("���ȭ�ƹ��������ʮ��",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --����
			elseif hqjl == 2 then
				AddPersonAttrib(0, "ָ������", 10)
				DrawStrBoxWaitKey("���ָ�����������ʮ��",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --����
			elseif hqjl == 3 then
				AddPersonAttrib(0, "��������", 10)
				DrawStrBoxWaitKey("����������������ʮ��",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --����
			elseif hqjl == 4 then
				AddPersonAttrib(0, "ˣ������", 10)
				DrawStrBoxWaitKey("���ˣ�����������ʮ��",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --����
			elseif hqjl == 5 then
				AddPersonAttrib(0, "�������", 10)
				DrawStrBoxWaitKey("���������������ʮ��",C_GOLD,CC.DefaultFont,nil,LimeGreen)
				Cls()  --����
			end
		elseif WAR.ZDDH == 211 then
			DrawStrBoxWaitKey("���⽱�������Ƿ��������Ṧ������ʮ��", C_GOLD, CC.DefaultFont)
			AddPersonAttrib(0, "������", 10)
			AddPersonAttrib(0, "�Ṧ", 10)
		elseif WAR.ZDDH == 86 then
			instruct_2(66, 1)
		elseif WAR.ZDDH == 4 then
			if JY.Person[0]["ʵս"] < 500 then
				QZXS(string.format("%s ʵս����%s��",JY.Person[0]["����"],30));
				JY.Person[0]["ʵս"] = JY.Person[0]["ʵս"] + 30
				if JY.Person[0]["ʵս"] > 500 then
					JY.Person[0]["ʵս"] = 500
				end
			end
		elseif WAR.ZDDH == 77 then
			if JY.Person[0]["ʵս"] < 500 then
				QZXS(string.format("%s ʵս����%s��",JY.Person[0]["����"],20));
				JY.Person[0]["ʵս"] = JY.Person[0]["ʵս"] + 20
				if JY.Person[0]["ʵս"] > 500 then
					JY.Person[0]["ʵս"] = 500
				end
			end
		elseif WAR.ZDDH > 42 and  WAR.ZDDH < 47 then
			if JY.Person[0]["ʵս"] < 500 then
				QZXS(string.format("%s ʵս����%s��",JY.Person[0]["����"],10));
				JY.Person[0]["ʵս"] = JY.Person[0]["ʵս"] + 10
				if JY.Person[0]["ʵս"] > 500 then
					JY.Person[0]["ʵս"] = 500
				end
			end
		elseif WAR.ZDDH == 161 then
			if JY.Person[0]["ʵս"] < 500 then
				QZXS(string.format("%s ʵս����%s��",JY.Person[0]["����"],30));
				JY.Person[0]["ʵս"] = JY.Person[0]["ʵս"] + 30
				if JY.Person[0]["ʵս"] > 500 then
					JY.Person[0]["ʵս"] = 500
				end
			end
		--սʤ����
		elseif WAR.ZDDH == 259 then
			DrawStrBoxWaitKey("���⽱������û��������ؼ�һ��", C_GOLD, CC.DefaultFont)
			instruct_32(275,1)
		--���۽����� ���ݵ��˲�ͬ������ͬ
		elseif WAR.ZDDH == 266 then
			--����
			if GetS(85, 40, 38, 4) == 64 then
				if JY.Person[0]["���һ���"] == 1 then
					DrawStrBoxWaitKey("���⽱����������һ����������������20% ", LimeGreen, 36,nil, C_GOLD)
					JY.Person[64]["�۽�����"] = 1
				else
					DrawStrBoxWaitKey("���ƺ������һ�������", LimeGreen, 36,nil, C_GOLD)
				end
			--����
			elseif GetS(85, 40, 38, 4) == 129 then
				DrawStrBoxWaitKey("���⽱������ı��������������70% ", LimeGreen, 36,nil, C_GOLD)
				JY.Person[129]["�۽�����"] = 1
			--�ֳ�Ӣ
			elseif GetS(85, 40, 38, 4) == 605 then
				DrawStrBoxWaitKey("���⽱����������������������50% ", LimeGreen, 36,nil, C_GOLD)
				JY.Person[605]["�۽�����"] = 1
			--����
			elseif GetS(85, 40, 38, 4) == 604 then
				DrawStrBoxWaitKey("���⽱��������������������700��", LimeGreen, 36,nil, C_GOLD)
				JY.Person[604]["�۽�����"] = 1
				--instruct_32(278,1)
			--������
			elseif GetS(85, 40, 38, 4) == 140 then
				if PersonKF(0, 47) then
					DrawStrBoxWaitKey("���⽱���������˶��¾Ž����洫", LimeGreen, 36,nil, C_GOLD)
					JY.Person[592]["�۽�����"] = 1
				else
					DrawStrBoxWaitKey("���ƺ������һ�������", LimeGreen, 36,nil, C_GOLD)
				end
			--��������
			elseif GetS(85, 40, 38, 4) == 27 then
				DrawStrBoxWaitKey("���⽱������ļ����ٶ����������8��", LimeGreen, 36,nil, C_GOLD)
				JY.Person[27]["�۽�����"] = 1
			--ɨ��
			elseif GetS(85, 40, 38, 4) == 114 then
				DrawStrBoxWaitKey("���⽱���������ѧ��ʶ�����100��", LimeGreen, 36,nil, C_GOLD)
				JY.Person[114]["�۽�����"] = 1
				AddPersonAttrib(0, "��ѧ��ʶ", 100)
			--����
			elseif GetS(85, 40, 38, 4) == 5 then
				DrawStrBoxWaitKey("���⽱������Ĺ��������ϵ����ֵȫ�������", LimeGreen, 36,nil, C_GOLD)
				JY.Person[5]["�۽�����"] = 1
				AddPersonAttrib(0, "������", 30)
				AddPersonAttrib(0, "������", 30)
				AddPersonAttrib(0, "�Ṧ", 30)
				AddPersonAttrib(0, "ȭ�ƹ���", 20)
				AddPersonAttrib(0, "ָ������", 20)
				AddPersonAttrib(0, "��������", 20)
				AddPersonAttrib(0, "ˣ������", 20)
				AddPersonAttrib(0, "�������", 20)
			--������
			elseif GetS(85, 40, 38, 4) == 606 then
				DrawStrBoxWaitKey("���⽱���������˾������ֵ�����", LimeGreen, 36,nil, C_GOLD)
				JY.Person[606]["�۽�����"] = 1
			end
		end
		--�԰�ɽս��ʤ����ð���
		if JY.Base["����"] == 153 and WAR.ZDDH ~= 226 then
			local anqi = math.random(28,35)
			local num = math.random(5)
			instruct_2(anqi,num)
		end
		r = true
	--ս��ʧ��
	elseif warStatus == 2 then
		--DrawStrBoxWaitKey("ս��ʧ��", C_WHITE, CC.DefaultFont)
		lib.LoadPNG(1, 999 * 2 , 295, 295, 1)
		ShowScreen();
		WaitKey();
		r = false
	end

	War_EndPersonData(isexp, warStatus)
	lib.ShowSlow(20, 1)
	if 0 <= JY.Scene[JY.SubScene]["��������"] then
		PlayMIDI(JY.Scene[JY.SubScene]["��������"])
	else
		PlayMIDI(0)
	end
	CleanMemory()
	lib.PicInit()

	--ս�����������¼��س�����ͼ
	lib.PicLoadFile(CC.SMAPPicFile[1], CC.SMAPPicFile[2], 0)	--�ӳ�����ͼ���ڴ�����0
	lib.LoadPNGPath(CC.HeadPath, 1, CC.HeadNum, limitX(CC.ScreenW/936*100,0,100))	--����ͷ���ڴ�����1
	lib.PicLoadFile(CC.ThingPicFile[1], CC.ThingPicFile[2], 2, 100, 100)	--��Ʒ��ͼ���ڴ�����2
	JY.Status = GAME_SMAP
	return r
end

--ɽ�����ã�����
function buzhen()
	if not inteam(92) then
		return
	end
	if WAR.ZDDH == 226 then
		return
	end
	local line = "Ҫ����������";
	local tiles = 2;
	if (WAR.ZDDH == 133 or WAR.ZDDH == 134) and WAR.MCRS == 1 then
		if JY.Person[0]["�Ա�"] == 0 then
			line = "��������¸ң�һ������սʮ�����֣���ǧ��С�ġ�"
		else
			line = "��������¸ң�һ������սʮ�����֣���ǧ��С�ġ�"
		end
		tiles = 4
	end
	say(line, 384,0,JY.Person[92]["����"])
	if not DrawStrBoxYesNo(-1, -1, "Ҫ����������", C_WHITE, CC.DefaultFont) then
		return
	end
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["�ҷ�"] then
			WAR.CurID = i
			WAR.ShowHead = 1
			--����ͳһΪ2��
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

--�޾Ʋ�����սǰ�˹�
function Pre_Yungong()
	if WAR.ZDDH == 226 then
		return
	end
	if true then
		return
	end
	local id, x1, y1;
	for j = 0, WAR.PersonNum - 1 do
		if WAR.Person[j]["������"] == 0 then
			id, x1, y1 = j, WAR.Person[j]["����X"], WAR.Person[j]["����Y"]
			break
		end
	end
	if x1 == nil then
		return
	end
	local s = WAR.CurID
	local r = JYMsgBox("սǰ�˹�", "սǰǿ���˹����ж�����۵�*Ҫ������", {"��","��"}, 2, WAR.tmp[5000+id])
	if r == 2 then
		local menu={};
		for i=1,CC.Kungfunum do
			menu[i]={JY.Wugong[JY.Person[0]["�书" .. i]]["����"],nil,0};
			if JY.Wugong[JY.Person[0]["�书" .. i]]["�书����"] == 6 then
				menu[i][3]=1;
			end
			--�����������
			if 0 == 0 and JY.Base["��׼"] == 6 and (JY.Person[0]["�书" .. i] == 106 or JY.Person[0]["�书" .. i] == 107 or JY.Person[0]["�书" .. i] == 108) then
				menu[i][3]=0;
			end
		end
		local main_neigong =  ShowMenu(menu,#menu,0,CC.MainSubMenuX+21+4*(CC.Fontsmall+CC.RowPixel),CC.MainSubMenuY,0,0,1,1,CC.DefaultFont,C_ORANGE, C_WHITE);
		if main_neigong ~= nil and main_neigong > 0 then
			WAR.CurID = id
			CleanWarMap(4, 0)
			SetWarMap(x1, y1, 4, 1)
			War_ShowFight(0, 0, 0, 0, 0, 0, 9)
			AddPersonAttrib(0, "����", -500);
			AddPersonAttrib(0, "����", -10);
			JY.Person[0]["�����ڹ�"] = JY.Person[0]["�书" .. main_neigong]
			WAR.CurID = s
		end
	end
end

--�޾Ʋ�����������λ�ò��Ŷ����ĺ���
function CurIDTXDH(id, eft, order, str, strColor, endFrame)
	--����������ɫ����
	if strColor == nil then
		strColor = C_GOLD
	end
	--����ǿ�ƽ���֡
	if endFrame == nil then
		endFrame = CC.Effect[eft]
	end
	local x0, y0 = WAR.Person[id]["����X"], WAR.Person[id]["����Y"]
	local hb = GetS(JY.SubScene, x0, y0, 4)
	local starteft = 0

	for i = 0, eft - 1 do
		starteft = starteft + CC.Effect[i]
	end

	local px = 0
	local py = 0

	--ʨ����������λ��
	if eft == 118 then
		py = CC.YScale * 4
	end

	--��ʯ��ٶ���λ��
	if eft == 124 then
		py = CC.YScale * 3
	end

	--�������λ��
	if eft == 149 then
		py = CC.YScale * 11
	end

	--��������߹�������λ��
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

--���㰵���˺�
function War_AnqiHurt(pid, emenyid, thingid, emeny)
	local num = nil
	local dam = nil
	if JY.Person[emenyid]["���˳̶�"] == 0 then
		num = JY.Thing[thingid]["������"] / 2 - Rnd(3)
	elseif JY.Person[emenyid]["���˳̶�"] <= 33 then
		num = math.modf(JY.Thing[thingid]["������"] *2 / 3) - Rnd(3)
	elseif JY.Person[emenyid]["���˳̶�"] <= 66 then
		num = JY.Thing[thingid]["������"] - Rnd(3)
	else
		num = math.modf(JY.Thing[thingid]["������"] *4 / 3) - Rnd(3)
	end

	num = math.modf(num - JY.Person[pid]["��������"]/4)
	WAR.Person[emeny]["���˵���"] = AddPersonAttrib(emenyid, "���˳̶�", math.modf(-num / 6))
	dam = num * WAR.AQBS
	local r = AddPersonAttrib(emenyid, "����", math.modf(dam))
	if (emenyid == 129 or emenyid == 65) and JY.Person[emenyid]["����"] <= 0 then
		JY.Person[emenyid]["����"] = 1
	end
	if JY.Person[emenyid]["����"] <= 0 then
		WAR.Person[WAR.CurID]["����"] = WAR.Person[WAR.CurID]["����"] + JY.Person[emenyid]["�ȼ�"] * 5
	end
	if JY.Thing[thingid]["���ж��ⶾ"] > 0 then
		num = math.modf(JY.Thing[thingid]["���ж��ⶾ"] + JY.Person[pid]["��������"] / 4)
		num = num - JY.Person[emenyid]["��������"]
		num = limitX(num, 0, CC.PersonAttribMax["�ö�����"])
		WAR.Person[emeny]["�ж�����"] = AddPersonAttrib(emenyid, "�ж��̶�", num)
	end
	--��˯״̬�ĵ��˻�����
	if WAR.CSZT[emenyid] ~= nil then
		WAR.CSZT[emenyid] = nil
	end
	return r
end

--�Զ�ҽ��
function War_AutoDoctor()
  local x1 = WAR.Person[WAR.CurID]["����X"]
  local y1 = WAR.Person[WAR.CurID]["����Y"]
  War_ExecuteMenu_Sub(x1, y1, 3, -1)
end

--�Զ���ҩ
--flag=2 ������3������4����  6 �ⶾ
function War_AutoEatDrug(flag)
	local pid = WAR.Person[WAR.CurID]["������"]
	local life = JY.Person[pid]["����"]
	local maxlife = JY.Person[pid]["�������ֵ"]
	local selectid = nil
	local minvalue = math.huge
	local shouldadd, maxattrib, str = nil, nil, nil
	if flag == 2 then
		maxattrib = JY.Person[pid]["�������ֵ"]
		shouldadd = maxattrib - JY.Person[pid]["����"]
		str = "������"
	elseif flag == 3 then
		maxattrib = JY.Person[pid]["�������ֵ"]
		shouldadd = maxattrib - JY.Person[pid]["����"]
		str = "������"
	elseif flag == 4 then
		maxattrib = CC.PersonAttribMax["����"]
		shouldadd = maxattrib - JY.Person[pid]["����"]
		str = "������"
	elseif flag == 6 then
		maxattrib = CC.PersonAttribMax["�ж��̶�"]
		shouldadd = JY.Person[pid]["�ж��̶�"]
		str = "���ж��ⶾ"
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

	--�ڶ�
	if inteam(pid) and WAR.Person[WAR.CurID]["�ҷ�"] == true then
		local extra = 0
		for i = 1, CC.MyThingNum do
			local thingid = JY.Base["��Ʒ" .. i]
			if thingid >= 0 then
				local add = Get_Add(thingid)
				if JY.Thing[thingid]["����"] == 3 and add > 0 then
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
				local thingid = JY.Base["��Ʒ" .. i]
				if thingid >= 0 then
					local add = Get_Add(thingid)
					if JY.Thing[thingid]["����"] == 3 and add > 0 then
						local v = add - shouldadd
						if v >= 0 and v < minvalue then
							minvalue = v
							selectid = thingid
						end
					end
				end
			end
		end
		--ʹ����Ʒ
		if UseThingEffect(selectid, pid) == 1 then
			instruct_32(selectid, -1)
		end
	--���ڶ�
	else
		local extra = 0
		for i = 1, 4 do
			local thingid = JY.Person[pid]["Я����Ʒ" .. i]
			local tids = JY.Person[pid]["Я����Ʒ����" .. i]
			if thingid >= 0 and tids > 0 then
				local add = Get_Add(thingid)
				if JY.Thing[thingid]["����"] == 3 and add > 0 then
					local v = shouldadd - add
					if v < 0 then		--���Լ�������, �����������Һ���ҩƷ
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
				local thingid = JY.Person[pid]["Я����Ʒ" .. i]
				local tids = JY.Person[pid]["Я����Ʒ����" .. i]
				if thingid >= 0 and tids > 0 then
					local add = Get_Add(thingid)
					if JY.Thing[thingid]["����"] == 3 and add > 0 then
						local v = add - shouldadd
						if v >= 0 and v < minvalue then
							minvalue = v
							selectid = thingid
						end
					end
				end
			end
		end
		--NPCʹ����Ʒ
		if UseThingEffect(selectid, pid) == 1 then
			instruct_41(pid, selectid, -1)
		end
	end
	lib.Delay(500)
end

--�Զ�����
function War_AutoEscape()
  local pid = WAR.Person[WAR.CurID]["������"]
  if JY.Person[pid]["����"] <= 5 then
    return
  end
  local x, y = nil, nil
  War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)		 --�����ƶ�����
  WarDrawMap(1)
  ShowScreen()
  local array = {}
  local num = 0

  for i = 0, CC.WarWidth - 1 do
    for j = 0, CC.WarHeight - 1 do
      if GetWarMap(i, j, 3) < 128 then
        local minDest = math.huge
        for k = 0, WAR.PersonNum - 1 do
          if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[k]["�ҷ�"] and WAR.Person[k]["����"] == false then
            local dx = math.abs(i - WAR.Person[k]["����X"])
            local dy = math.abs(j - WAR.Person[k]["����Y"])
	          if dx + dy < minDest then		--���㵱ǰ������������λ��
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

  War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)
  War_MovePerson(x, y)	--�ƶ�����Ӧ��λ��
end

--�Զ�ս��
function War_AutoMenu()
	local pid = WAR.Person[WAR.CurID]["������"]
	WAR.AutoFight = 1
	WAR.ShowHead = 0
	Cls()
	if JY.Person[pid]["�����Զ�"] == 1 then
		return 0
	else
		War_Auto()
		return 1
	end
end

--������ƶ�����
--id ս����id��
--stepmax �������
--flag=0  �ƶ�����Ʒ�����ƹ���1 �书���ö�ҽ�Ƶȣ������ǵ�·��
--flag=2  ���ӽ���
function War_CalMoveStep(id, stepmax, flag)
  CleanWarMap(3, 255)
  local x = WAR.Person[id]["����X"]
  local y = WAR.Person[id]["����Y"]
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

--�ж�x,y�Ƿ�Ϊ���ƶ�λ��
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

--�ⶾ�˵�
function War_DecPoisonMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(2)
	WAR.ShowHead = 1
	Cls()
	return r
end

--�Ƿ񱳴�
function IsBackstab(warpid, wareid)
	return WAR.Person[warpid]["�˷���"] == WAR.Person[wareid]["�˷���"]
end

--�жϹ�������Եķ���
function War_Direct(x1, y1, x2, y2)
	local x = x2 - x1
	local y = y2 - y1
	--lib.Debug("x "..x.."  y "..y)
	if x == 0 and y == 0 then
		return WAR.Person[WAR.CurID]["�˷���"]
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

--ҽ�Ʋ˵�
function War_DoctorMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(3)
	WAR.ShowHead = 1
	Cls()
	return r
end

---ִ��ҽ�ƣ��ⶾ�ö�
---flag=1 �ö��� 2 �ⶾ��3 ҽ�� 4 ����
---thingid ������Ʒid
function War_ExecuteMenu(flag, thingid)
	local pid = WAR.Person[WAR.CurID]["������"]
	local step = nil
	local sts =  nil
	if flag == 1 then
		step = math.modf(JY.Person[pid]["�ö�����"] / 40)
	elseif flag == 2 then
		step = math.modf(JY.Person[pid]["�ⶾ����"] / 40)
	elseif flag == 3 then
		step = math.modf(JY.Person[pid]["ҽ������"] / 40)
	elseif flag == 4 then
		step = math.modf(JY.Person[pid]["��������"] / 15) + 1
	end
	War_CalMoveStep(WAR.CurID, step, 1)
	--���Ӳ��������7*7��ʾ
	if pid == 0 and JY.Base["��׼"] == 8 and flag == 3 then
		sts = 1
	elseif pid == 0 and JY.Base["��׼"] == 9 and flag == 1 then
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

--ѡ���书�ĺ������ֶ���AI����������
function War_FightSelectType(movefanwei, atkfanwei, x, y, wugong)
	local x0 = WAR.Person[WAR.CurID]["����X"]
	local y0 = WAR.Person[WAR.CurID]["����Y"]
	if x == nil and y == nil then
		x, y = War_KfMove(movefanwei, atkfanwei, wugong)
		if x == nil then
			lib.GetKey()
			Cls()
			return
		end
	--�޾Ʋ�����AIҲ��ʾѡ��Χ
	else
		WarDrawAtt(x, y, atkfanwei, 4)
		WarDrawMap(1, x, y)
		ShowScreen()
		
		CleanWarMap(7,0)
		lib.Delay(200)
	end
	if not War_Direct(x0, y0, x, y) then
		WAR.Person[WAR.CurID]["�˷���"] = WAR.Person[WAR.CurID]["�˷���"]
	else
		WAR.Person[WAR.CurID]["�˷���"] = War_Direct(x0, y0, x, y)
	end
	SetWarMap(x, y, 4, 1)
	WAR.EffectXY = {}
	return x, y
end

--������һ�����ƶ�������
function War_FindNextStep(steparray, step, flag, id)
	local num = 0
	local step1 = step + 1

	--ZOC�ж�
	local fujinnum = function(tx, ty)
		if flag ~= 0 or id == nil then
			return 0
		end
		local tnum = 0
		local wofang = WAR.Person[id]["�ҷ�"]
		local tv = nil
		tv = GetWarMap(tx + 1, ty, 2)
		if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
			tnum = 9999
		end
		tv = GetWarMap(tx - 1, ty, 2)
		if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
			tnum = 999
		end
		tv = GetWarMap(tx, ty + 1, 2)
		if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
			tnum = 999
		end
		tv = GetWarMap(tx, ty - 1, 2)
		if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
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

--�ж��Ƿ��ܴ򵽵���
function War_GetCanFightEnemyXY()
	local num, x, y = nil, nil, nil
	num, x, y = War_realjl(WAR.CurID)
	if num == -1 then
		return
	end
	return x, y
end

--�ƶ�
function War_MoveMenu()
  if WAR.Person[WAR.CurID]["������"] ~= -1 then
    WAR.ShowHead = 0
    if WAR.Person[WAR.CurID]["�ƶ�����"] <= 0 then
      return 0
    end
    War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["�ƶ�����"], 0)
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
      if WAR.Person[i]["�ҷ�"] ~= WAR.Person[WAR.CurID]["�ҷ�"] and WAR.Person[i]["����"] == false then
        ydd[n] = i
        n = n + 1
      end
    end
    local dx = ydd[math.random(n - 1)]
    local DX = WAR.Person[dx]["����X"]
    local DY = WAR.Person[dx]["����Y"]
    local YDX = {DX + 1, DX - 1, DX}
    local YDY = {DY + 1, DY - 1, DY}
    local ZX = YDX[math.random(3)]
    local ZY = YDY[math.random(3)]
    if not SceneCanPass(ZX, ZY) or GetWarMap(ZX, ZY, 2) < 0 then
      SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
      SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
      WAR.Person[WAR.CurID]["����X"] = ZX
      WAR.Person[WAR.CurID]["����Y"] = ZY
      SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
      SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
    end
  end
  return 1
end

--�����ƶ�
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
	--�����ƶ�����
	movetable.num = movenum
	movetable.now = 0
	WAR.Person[WAR.CurID].Move = movetable
	if WAR.Person[WAR.CurID]["�ƶ�����"] < movenum then
		movenum = WAR.Person[WAR.CurID]["�ƶ�����"]
		WAR.Person[WAR.CurID]["�ƶ�����"] = 0
	else
		WAR.Person[WAR.CurID]["�ƶ�����"] = WAR.Person[WAR.CurID]["�ƶ�����"] - movenum
	end
	--�ƶ�����
	--������������ʾ
	--��Ϧ��Ů���۽����������Ƿ�ѧ�����ٲ�
	if WAR.Person[WAR.CurID]["������"] == 0 and JY.Base["��׼"] > 0 and JY.Person[615]["�۽�����"] == 1 and movenum > 2 then
		local a = 0
		local gender = 0
		if JY.Person[0]["�Ա�"] > 0 then
			gender = 1
		end
		for i = 1, movenum do
			local t1 = lib.GetTime()
			if a == 6 then
				a = 0
			end
			if i == 1 then
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
				SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
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
			WAR.Person[WAR.CurID]["����X"] = movetable[i].x
			WAR.Person[WAR.CurID]["����Y"] = movetable[i].y
			WAR.Person[WAR.CurID]["�˷���"] = movetable[i].direct
			if i < movenum then
				WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic2(WAR.CurID, gender) + (a)*2
			else
				WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)
			end
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
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
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
			WAR.Person[WAR.CurID]["����X"] = movetable[i].x
			WAR.Person[WAR.CurID]["����Y"] = movetable[i].y
			WAR.Person[WAR.CurID]["�˷���"] = movetable[i].direct
			WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
			SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
			WarDrawMap(0)
			ShowScreen()
			local t2 = lib.GetTime()
			if i < movenum and t2 - t1 < 2 * CC.BattleDelay then
			  lib.Delay(2 * CC.BattleDelay - (t2 - t1))
			end
		end
	end
	--�����Ṧ�Ļ�����ZOC�ƶ�����0����֮��0
	if JY.Person[WAR.Person[WAR.CurID]["������"]]["�����Ṧ"] == 0 then
		local fujinnum = function(tx, ty)
			local tnum = 0
			local wofang = WAR.Person[WAR.CurID]["�ҷ�"]
			local tv = nil
			tv = GetWarMap(tx + 1, ty, 2)
			if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx - 1, ty, 2)
			if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx, ty + 1, 2)
			if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
				tnum = 999
			end
			tv = GetWarMap(tx, ty - 1, 2)
			if tv ~= -1 and WAR.Person[tv]["�ҷ�"] ~= wofang then
				tnum = 999
			end
			return tnum
		end
		if fujinnum(WAR.Person[WAR.CurID]["����X"],WAR.Person[WAR.CurID]["����Y"]) ~= 0 then
			WAR.Person[WAR.CurID]["�ƶ�����"] = 0
		end
	end
end

---�ö��˵�
function War_PoisonMenu()
	WAR.ShowHead = 0
	local r = War_ExecuteMenu(1)
	WAR.ShowHead = 1
	Cls()
	return r
end

--ս����Ϣ
function War_RestMenu()
	if WAR.CurID and WAR.CurID >= 0  then
		local pid = WAR.Person[WAR.CurID]["������"]
		--[[�߻�����Ϣ
		if WAR.tmp[1000 + pid] == 1 then
			return 1
		end
		local vv = math.modf(JY.Person[pid]["����"] / 100 - JY.Person[pid]["���˳̶�"] / 50 - JY.Person[pid]["�ж��̶�"] / 50) + 2
		if WAR.Person[WAR.CurID]["�ƶ�����"] > 0 then
			vv = vv + 2
		end
		if inteam(pid) then
			vv = vv + math.random(3)
		else
			vv = vv + 6
		end
		vv = (vv) / 120
		local v = 3 + Rnd(3)
		WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(pid, "����", v)
		if JY.Person[pid]["����"] > 0 then
			v = 3 + math.modf(JY.Person[pid]["�������ֵ"] / JY.Person[pid]["Ѫ������"] * (vv))
			WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(pid, "����", v)
			v = 3 + math.modf(JY.Person[pid]["�������ֵ"] * (vv))
			WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(pid, "����", v)
		end

		War_Show_Count(WAR.CurID);		--��ʾ��ǰ�����˵ĵ���]]

		--��������Ϣ������+����
		if match_ID(pid, 606) then
			Cls()
			WAR.Actup[pid] = 2;
			WAR.Defup[pid] = 1
			CurIDTXDH(WAR.CurID, 85,1);
			DrawStrBox(-1, -1, "�˳��ᢡ���ʤǧ��", LimeGreen, CC.DefaultFont,C_GOLD)
			ShowScreen()
			lib.Delay(400)
			return 1;
		else
			return 1
		end
	end
end

--ս���鿴״̬
function War_StatusMenu()
	local x = WAR.Person[WAR.CurID]["����X"];
    local y = WAR.Person[WAR.CurID]["����Y"];
    WAR.ShowHead = 0
    War_CalMoveStep(WAR.CurID, 128, 1);
    WarDrawMap(1, x, y);
    ShowScreen();
    x, y = War_SelectMove()
	if lib.GetWarMap(x, y, 2) > 0 or lib.GetWarMap(x, y, 5) > 0 then
		local tdID = lib.GetWarMap(x, y, 2)
		local eid = WAR.Person[tdID]["������"]
		ShowPersonStatus(1, eid)
	end
    --if x == nil then return end
    WAR.ShowHead = 1
end

--ս����Ʒ�˵�
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
		local id = JY.Base["��Ʒ" .. i + 1]
		if id >= 0 and (JY.Thing[id]["����"] == 1 or JY.Thing[id]["����"] == 3 or JY.Thing[id]["����"] == 4) then
			thing[num] = id
			thingnum[num] = JY.Base["��Ʒ����" .. i + 1]
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


--�Զ�ս���ж��Ƿ���ҽ��
function War_ThinkDoctor()
  local pid = WAR.Person[WAR.CurID]["������"]
  if JY.Person[pid]["����"] < 50 or JY.Person[pid]["ҽ������"] < 20 then
    return -1
  end
  local rate = -1
  local v = JY.Person[pid]["�������ֵ"] - JY.Person[pid]["����"]
  if JY.Person[pid]["ҽ������"] < v / 4 then
    rate = 30
  elseif JY.Person[pid]["ҽ������"] < v / 3 then
      rate = 50
  elseif JY.Person[pid]["ҽ������"] < v / 2 then
      rate = 70
  else
    rate = 90
  end
  if Rnd(100) < rate then
    return 5
  end
  return -1
end

--�ܷ��ҩ���Ӳ���
--flag=2 ������3������4����  6 �ⶾ
function War_ThinkDrug(flag)
  local pid = WAR.Person[WAR.CurID]["������"]
  local str = nil
  local r = -1
  if flag == 2 then
    str = "������"
  elseif flag == 3 then
    str = "������"
  elseif flag == 4 then
    str = "������"
  elseif flag == 6 then
    str = "���ж��ⶾ"
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

  --�����Ƿ���ҩƷ
  if inteam(pid) and WAR.Person[WAR.CurID]["�ҷ�"] == true then
    for i = 1, CC.MyThingNum do
      local thingid = JY.Base["��Ʒ" .. i]
      if thingid >= 0 and JY.Thing[thingid]["����"] == 3 and Get_Add(thingid) > 0 then
        r = flag
        break;
      end
    end
  else
    for i = 1, 4 do
      local thingid = JY.Person[pid]["Я����Ʒ" .. i]
      if thingid >= 0 and JY.Thing[thingid]["����"] == 3 and Get_Add(thingid) > 0 then
        r = flag
        break;
      end
    end
  end
  return r
end

--ʹ�ð���
function War_UseAnqi(id)
	return War_ExecuteMenu(4, id)
end

--��ʼ��ս������
function WarLoad(warid)
	WarSetGlobal()
	local data = Byte.create(CC.WarDataSize)
	Byte.loadfile(data, CC.WarFile, warid * CC.WarDataSize, CC.WarDataSize)
	LoadData(WAR.Data, CC.WarData_S, data)
	WAR.ZDDH = warid
end

--����ս����ͼ
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

--����������ͼ
function WarSetPerson()
	CleanWarMap(2, -1)
	CleanWarMap(5, -1)
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 2, i)
			SetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 5, WAR.Person[i]["��ͼ"])
		end
	end
end

--��ʾ�书�������������˶�������Ч��
function War_ShowFight(pid, wugong, wugongtype, level, x, y, eft, ZHEN_ID)
	--����ʱ����ʾѪ��
	WAR.ShowHP = 0

	--û�кϻ�
	if not ZHEN_ID then
		ZHEN_ID = -1
	end

	--�ڹ�
	if wugongtype == 6 then
		wugongtype = WAR.NGXS
	end

	--�޾Ʋ���������һ���µĶ���˳��
	if wugongtype == 2 then
		wugongtype = 1
	elseif wugongtype > 2 and wugongtype < 6 then
		wugongtype = wugongtype - 1
	end

	local x0 = WAR.Person[WAR.CurID]["����X"]
	local y0 = WAR.Person[WAR.CurID]["����Y"]

	local using_anqi = 0
	local anqi_name;
	--��������
	if wugongtype == -1 then
		using_anqi = 1
		anqi_name = JY.Thing[eft]["����"]
		--�����ֺ�ɳ��Ӱ
		if match_ID(pid, 83) then
			anqi_name = "��ɳ��Ӱ��"..anqi_name
		end
		eft = JY.Thing[eft]["�����������"]
	end

	--ɨ����ɮ  �������
	if match_ID(pid, 114) then
		eft = math.random(100)
	end

	--��Ȼ���⶯��
	if wugong == 25 and WAR.ARJY == 1 then
		eft = 7
	end

	--���߰��嶯��
	if wugong == 40 and WAR.JSAY == 1 then
		eft = 44
	end

	--������
	if wugong == 30 and PersonKF(pid,175) then
		eft = 139
	end
	--����̩ɽ
	if wugong == 31 and PersonKF(pid,175) then
		eft = 138
	end
	--��������
	if wugong == 32 and PersonKF(pid,175) then
		eft = 142
	end
	--��������
	if wugong == 33 and PersonKF(pid,175) then
		eft = 140
	end
	--����̫��
	if wugong == 34 and PersonKF(pid,175) then
		eft = 141
	end

	--�޾Ʋ�������Ч����
	if pid == 0 and JY.Base["����"] == 1 then
		if JY.Person[0]["�Ա�"] == 0 then
			eft = 65
		else
			eft = 8
		end
	end

	--������ǹ��
	if match_ID(pid,650) and wugong == 68 then
		eft = 150
	end

	--����ʤ���ж���
	if wugong == 47 and WAR.FQY == 1 then
		eft = 84
	end

	local ex, ey = -1, -1;

	--���Զ���
	--eft = 110;

	--�����м��ʳ��������
	if pid == 0 and GetS(53, 0, 4, 5) == 1 and JLSD(0,30,pid)  then
		eft = 110;
	end

	--ָ��XY����ôֻ��ʾ��һ������ʾ����
	if eft == 110 then
		ex, ey = x, y;
	end

	--�����񽣵���������Ϊȭ��
	if wugong == 49 then
		wugongtype = 1
	end

	--�ϻ�����
	local ZHEN_pid, ZHEN_type, ZHEN_startframe, ZHEN_fightframe = nil, nil, nil, nil
	if ZHEN_ID >= 0 then
		ZHEN_pid = WAR.Person[ZHEN_ID]["������"]
		ZHEN_type = wugongtype
		ZHEN_startframe = 0
		ZHEN_fightframe = 0
	end

	local fightdelay, fightframe, sounddelay = nil, nil, nil
	if wugongtype >= 0 then
		fightdelay = JY.Person[pid]["���ж����ӳ�" .. wugongtype + 1]
		fightframe = JY.Person[pid]["���ж���֡��" .. wugongtype + 1]
		sounddelay = JY.Person[pid]["�书��Ч�ӳ�" .. wugongtype + 1]
	else
		fightdelay = 0
		fightframe = -1
		sounddelay = -1
	end

	if fightdelay == 0 or fightframe == 0 then
		for i = 1, 5 do
			if JY.Person[pid]["���ж���֡��" .. i] ~= 0 then
				fightdelay = JY.Person[pid]["���ж����ӳ�" .. i]
				fightframe = JY.Person[pid]["���ж���֡��" .. i]
				sounddelay = JY.Person[pid]["�书��Ч�ӳ�" .. i]
				wugongtype = i - 1
			end
		end
	end

	if ZHEN_ID >= 0 then
		if JY.Person[ZHEN_pid]["���ж���֡��" .. ZHEN_type + 1] == 0 then
			for i = 1, 5 do
				if JY.Person[ZHEN_pid]["���ж���֡��" .. i] ~= 0 then
					ZHEN_type = i - 1
					ZHEN_fightframe = JY.Person[ZHEN_pid]["���ж���֡��" .. i]
				end
			end
		else
			ZHEN_fightframe = JY.Person[ZHEN_pid]["���ж���֡��" .. ZHEN_type + 1]
		end
	end

	local framenum = fightdelay + CC.Effect[eft]
	local startframe = 0
	if wugongtype >= 0 then
		for i = 0, wugongtype - 1 do
			startframe = startframe + 4 * JY.Person[pid]["���ж���֡��" .. i + 1]
		end
	end
	if ZHEN_ID >= 0 and ZHEN_type >= 0 then
		for i = 0, ZHEN_type - 1 do
			ZHEN_startframe = ZHEN_startframe + 4 * JY.Person[ZHEN_pid]["���ж���֡��" .. i + 1]
		end
	end

	local starteft = 0
	for i = 0, eft - 1 do
		starteft = starteft + CC.Effect[i]
	end

	WAR.Person[WAR.CurID]["��ͼ����"] = 0
	WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)
	if ZHEN_ID >= 0 then
		WAR.Person[ZHEN_ID]["��ͼ����"] = 0
		WAR.Person[ZHEN_ID]["��ͼ"] = WarCalPersonPic(ZHEN_ID)
	end

	local oldpic = WAR.Person[WAR.CurID]["��ͼ"] / 2		--��ǰ��ͼ��λ��
	local oldpic_type = 0
	local oldeft = -1
	local kfname = JY.Wugong[wugong]["����"]
	local showsize = CC.FontBig
	local showx = CC.ScreenW / 2 - showsize * string.len(kfname) / 4
	local hb = GetS(JY.SubScene, x0, y0, 4)

	--��ʾ�书���ŵ���Ч����4
	if wugong ~= 0 then
		if WAR.LHQ_BNZ == 1 then
			kfname = "������"
		end
		if WAR.JGZ_DMZ == 1 then
			kfname = "��Ħ��"
		end
		if WAR.WD_CLSZ == 1 then
			kfname = "��������"
		end
	end

	--������ܵķ�������
	if WAR.hit_DGQB == 1 then
		kfname = "�����޽�"
	end

	--���߰���
	if WAR.JSAY == 1 then
		kfname = "���塤���߿���"
	end

	--�������嶾��ʾ����
	if wugong == 3 and match_ID(pid, 83) and WAR.HTS > 0 then
		kfname = kfname.." X "..WAR.HTS
	end

	--�ڹ���ʾ�������ϵ
	if WAR.NGXS > 0 then
		local display = {"��ȭ","��ָ","ľ��","��","ˮ��"}
		kfname = kfname.."��"..display[WAR.NGXS]
	end

	if ZHEN_ID >= 0 then
		kfname = "˫�˺ϻ���"..kfname
	end

	--��Ч����4���书������ʾ
	if wugong > 0 or WAR.hit_DGQB == 1 then				--ʹ���书ʱ����ʾ��������ܷ���Ҳ��ʾ
		if WAR.Person[WAR.CurID]["��Ч����4"] ~= nil then
			for i=1, 20 do
				local n, strs = Split(WAR.Person[WAR.CurID]["��Ч����4"], "��");
				local len = string.len(WAR.Person[WAR.CurID]["��Ч����4"]);
				local color = RGB(255,40,10);
				local off = 0;
				for j=1, n do
					if strs[j] == "����" or strs[j] == "�츳�⹦.¯����"
					or strs[j] == "��������˫����" or strs[j] == "Ӣ����˫������" or strs[j] == "������ӳ��ȸ��"
					or strs[j] == "̫��֮��.Բת����" then
						color = M_LightBlue;
					elseif strs[j] == "���һ���" then
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
		--�书��ʾ
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

	--������ʾ
	if using_anqi == 1 then
		for i = 5, 10 do
			if WAR.KHSZ == 1 then
				KungfuString("��������", CC.ScreenW / 2 -#anqi_name/2, CC.ScreenH / 3 - 20 - hb  , C_RED, CC.FontBig+i, CC.FontName, 0)
			else
				KungfuString(anqi_name.."��"..WAR.AQBS, CC.ScreenW / 2 -#anqi_name/2, CC.ScreenH / 3 - 20 - hb  , C_GOLD, CC.FontBig+i, CC.FontName, 0)
			end
			ShowScreen()

			lib.Delay(2)
			if i == 10 then
				lib.Delay(300)
			end
			Cls()
		end
	end

  --��ʾ��������
  for i = 0, framenum - 1 do
	if JY.Restart == 1 then
		break
	end
    local tstart = lib.GetTime()
    local mytype = nil
    if fightframe > 0 then
      WAR.Person[WAR.CurID]["��ͼ����"] = 1
      mytype = 4 + WAR.CurID
      if i < fightframe then
        WAR.Person[WAR.CurID]["��ͼ"] = (startframe + WAR.Person[WAR.CurID]["�˷���"] * fightframe + i) * 2
      end
    else
      WAR.Person[WAR.CurID]["��ͼ����"] = 0
      WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)
      mytype = 0
    end

    if ZHEN_ID >= 0 then
      if ZHEN_fightframe > 0 then
        WAR.Person[ZHEN_ID]["��ͼ����"] = 1
        if i < ZHEN_fightframe and i < framenum - 1 then
          WAR.Person[ZHEN_ID]["��ͼ"] = (ZHEN_startframe + WAR.Person[ZHEN_ID]["�˷���"] * ZHEN_fightframe + i) * 2
        else
          WAR.Person[ZHEN_ID]["��ͼ"] = WarCalPersonPic(ZHEN_ID)
        end
      else
        WAR.Person[ZHEN_ID]["��ͼ����"] = 0
        WAR.Person[ZHEN_ID]["��ͼ"] = WarCalPersonPic(ZHEN_ID)
      end
      SetWarMap(WAR.Person[ZHEN_ID]["����X"], WAR.Person[ZHEN_ID]["����Y"], 5, WAR.Person[ZHEN_ID]["��ͼ"])
    end

    if i == sounddelay then
      PlayWavAtk(JY.Wugong[wugong]["������Ч"])		--
    end

    if i == fightdelay then
      PlayWavE(eft)
    end

	--�����񽣵���Ч
    if i == 1 and WAR.LMSJwav == 1 then
		PlayWavAtk(31)
		WAR.LMSJwav = 0
    end

    local pic = WAR.Person[WAR.CurID]["��ͼ"] / 2

    lib.SetClip(0, 0, 0, 0)

    oldpic = pic
    oldpic_type = mytype

    --�޾Ʋ�����������Ч������ʾ 8-3
    if i < fightdelay then
		WarDrawMap(4, pic * 2, mytype, -1)

		--Ԭ��־����������ʾ
		--�����ҷ�
		if match_ID(pid, 54) and inteam(pid) and using_anqi == 0 and WAR.BJ == 1 then
			local cri_factor = 1.5 + 0.1 * JY.Base["��������"]
			KungfuString("������"..cri_factor, CC.ScreenW -230 +i*2, CC.ScreenH / 3 - 50 - hb -i*2, C_RED, CC.FontBig+i*2, CC.FontName, 0)
  		end

		if i == 1 and WAR.Person[WAR.CurID]["��Ч����"] ~= -1 then
			local theeft = WAR.Person[WAR.CurID]["��Ч����"]
			local sf = 0
			for ii = 0, theeft - 1 do
				sf = sf + CC.Effect[ii]
			end
			local ssid = lib.SaveSur(CC.ScreenW/2 - 11 * CC.XScale, CC.ScreenH/2 - hb - 18 * CC.YScale, CC.ScreenW/2 + 11 * CC.XScale, CC.ScreenH/2 - hb + 5 * CC.YScale)

			for ii = 1, CC.Effect[theeft] do
				lib.GetKey()
				lib.PicLoadCache(3, (sf+ii) * 2, CC.ScreenW/2 , CC.ScreenH/2  - hb, 2, 192, nil, 0, 0)
				if WAR.Person[WAR.CurID]["��Ч����0"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["��Ч����0"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
				end
				if WAR.Person[WAR.CurID]["��Ч����1"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["��Ч����1"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_RED, CC.FontSmall5, CC.FontName, 3)
				end
				if WAR.Person[WAR.CurID]["��Ч����2"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["��Ч����2"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_GOLD, CC.FontSmall5, CC.FontName, 2)
				end
				if WAR.Person[WAR.CurID]["��Ч����3"] ~= nil then
					KungfuString(WAR.Person[WAR.CurID]["��Ч����3"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_WHITE, CC.FontSmall5, CC.FontName, 1)
				end
				ShowScreen()
				lib.Delay(30)
				lib.LoadSur(ssid, CC.ScreenW/2 - 11 * CC.XScale, CC.ScreenH/2 - hb - 18 * CC.YScale)

			end
			lib.FreeSur(ssid)
			WAR.Person[WAR.CurID]["��Ч����"] = -1
		else
			if WAR.Person[WAR.CurID]["��Ч����0"] ~= nil or WAR.Person[WAR.CurID]["��Ч����1"] ~= nil or WAR.Person[WAR.CurID]["��Ч����2"] ~= nil or WAR.Person[WAR.CurID]["��Ч����3"] ~= nil then
				KungfuString(WAR.Person[WAR.CurID]["��Ч����0"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
				KungfuString(WAR.Person[WAR.CurID]["��Ч����1"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_RED, CC.FontSmall5, CC.FontName, 3)
				KungfuString(WAR.Person[WAR.CurID]["��Ч����2"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_GOLD, CC.FontSmall5, CC.FontName, 2)
				KungfuString(WAR.Person[WAR.CurID]["��Ч����3"], CC.ScreenW / 2, CC.ScreenH / 2 - hb, C_WHITE, CC.FontSmall5, CC.FontName, 1)
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
  WAR.Person[WAR.CurID]["��ͼ����"] = 0
  WAR.Person[WAR.CurID]["��ͼ"] = WarCalPersonPic(WAR.CurID)

  --�޾Ʋ��������е������ð�ɫ��ʾ
  WarSetPerson()
  WarDrawMap(0)
  ShowScreen()
  lib.Delay(200)
  WarDrawMap(2)
  ShowScreen()
  lib.Delay(200)
  WarDrawMap(0)
  ShowScreen()

  --���㹥��������
  local HitXY = {}
  local HitXYNum = 0
  local hnum = 13;		--HitXY�ĳ��ȸ���
  for i = 0, WAR.PersonNum - 1 do
    local x1 = WAR.Person[i]["����X"]
    local y1 = WAR.Person[i]["����Y"]
	--����Ч���е�Ҳ��ʾ
    if WAR.Person[i]["����"] == false and (GetWarMap(x1, y1, 4) > 1 or WAR.TXXS[WAR.Person[i]["������"]] == 1) then
      SetWarMap(x1, y1, 4, 1)
      --local n = WAR.Person[i]["����"]
      local hp = WAR.Person[i]["��������"];
      local mp = WAR.Person[i]["��������"];
      local tl = WAR.Person[i]["��������"];
      local ed = WAR.Person[i]["�ж�����"];
      local dd = WAR.Person[i]["�ⶾ����"];
      local ns = WAR.Person[i]["���˵���"];

      HitXY[HitXYNum] = {x1, y1, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};		--x, y, ����, ����, ����, ��Ѩ, ��Ѫ, �ж�, �ⶾ, ���ˣ����⣬����

		if hp ~= nil then
	      if hp == 0 then			--��ʾ�ܵ�������
	      	HitXY[HitXYNum][3] = "miss";
	      elseif hp > 0 then
	      	HitXY[HitXYNum][3] = "+"..hp;
	      else
	      	HitXY[HitXYNum][3] = hp;
	      end
	    end


      if mp ~= nil then			--��ʾ�����仯
      	if mp > 0 then
      		HitXY[HitXYNum][5] = "����+"..mp;
      	elseif mp ==  0 then
      		HitXY[HitXYNum][5] = nil;			--�仯Ϊ0ʱ����ʾ
      	else
      		HitXY[HitXYNum][5] = "����"..mp;
      	end
      end

      if tl ~= nil then			--��ʾ�����仯
      	if tl > 0 then
      		HitXY[HitXYNum][6] = "����+"..tl;
      	elseif tl == 0 then
      		HitXY[HitXYNum][6] = nil;
      	else
      		HitXY[HitXYNum][6] = "����"..tl;
      	end
      end

      if WAR.FXXS[WAR.Person[i]["������"]] ~= nil and WAR.FXXS[WAR.Person[i]["������"]] == 1 then			--��ʾ�Ƿ��Ѩ
       	HitXY[HitXYNum][7] = "��Ѩ "..WAR.FXDS[WAR.Person[i]["������"]];
       	WAR.FXXS[WAR.Person[i]["������"]] = 0
      end

      if WAR.LXXS[WAR.Person[i]["������"]] ~=nil and WAR.LXXS[WAR.Person[i]["������"]] == 1 then		--��ʾ�Ƿ���Ѫ
      	HitXY[HitXYNum][8] = "��Ѫ "..WAR.LXZT[WAR.Person[i]["������"]];
        WAR.LXXS[WAR.Person[i]["������"]] = 0
      end

      if ed ~= nil then				--��ʾ�ж�
      	if ed == 0 then
      		HitXY[HitXYNum][9] = nil;
      	else
      		HitXY[HitXYNum][9] = "�ж���"..ed;
      	end
      end

      if dd ~= nil then			--��ʾ�ⶾ
      	if dd  == 0 then
      		HitXY[HitXYNum][4] = nil;
      	else
      		HitXY[HitXYNum][4] = "�ж���"..dd;
      	end
      end

      if ns ~= nil then		--��ʾ����
      	if ns == 0 then
      		HitXY[HitXYNum][10] = nil;
      	elseif ns > 0 then
      		HitXY[HitXYNum][10] = "���ˡ�"..ns;
      	else
      		HitXY[HitXYNum][10] = "���ˡ�"..ns;
      	end
      end

		if WAR.BFXS[WAR.Person[i]["������"]] == 1 then		--��ʾ�Ƿ񱻱���
			HitXY[HitXYNum][11] = "���� "..JY.Person[WAR.Person[i]["������"]]["����̶�"];
			WAR.BFXS[WAR.Person[i]["������"]] = 0
		end

		if WAR.ZSXS[WAR.Person[i]["������"]] == 1 then		--��ʾ�Ƿ�����
			HitXY[HitXYNum][12] = "���� "..JY.Person[WAR.Person[i]["������"]]["���ճ̶�"];
			WAR.ZSXS[WAR.Person[i]["������"]] = 0
		end

		HitXYNum = HitXYNum + 1
    end

		--͵��������ת����͵
		if WAR.TD > -1 then
			if WAR.TD == 118 then
				say("����Ҫ����Ľ�ݸ�����͵�������ߺߣ��±��Ӱɣ�", 51,0)
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
	--������Ч������ʾ
	for ii = 1, 20 do
		if JY.Restart == 1 then
			break
		end
		local yanshi = false
		local yanshi2 = false		--�޶���ʱ���ӳ�
		for i = 0, WAR.PersonNum - 1 do
			lib.GetKey()
			if WAR.Person[i]["����"] == false then
				local theeft = WAR.Person[i]["��Ч����"]
				if theeft ~= -1 and ii < CC.Effect[theeft] then
					local dx = WAR.Person[i]["����X"] - x0
					local dy = WAR.Person[i]["����Y"] - y0
					local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
					local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
					local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

					local py = 0

					ry = ry - hb
					starteft = ii
					for i = 0, WAR.Person[i]["��Ч����"] - 1 do
						starteft = starteft + CC.Effect[i]
					end

					--�������Ķ���λ��
					if theeft == 125 then
						py = CC.YScale * 5
					end

					--��������߹�������λ��
					if theeft == 135 then
						py = CC.YScale * 2
					end

					--�����������Խ���������λ��
					if theeft == 137 then
						py = CC.YScale * 18
						starteft = starteft + 12
					end

					--�������λ��
					if theeft == 149 then
						py = CC.YScale * 11
					end

					lib.PicLoadCache(3, (starteft) * 2, rx, ry + py, 2, 192, nil, 0, 0)

					--�޾Ʋ�������Ч����һ�����������������ʾ�ķ�ʽ
					--if ii < TPXS[i] * TP and (TPXS[i] - 1) * TP < ii then	
						KungfuString(WAR.Person[i]["��Ч����3"], rx, ry, C_WHITE, CC.FontSmall5, CC.FontName, 1)
						KungfuString(WAR.Person[i]["��Ч����2"], rx, ry, C_GOLD, CC.FontSmall5, CC.FontName, 2)
						KungfuString(WAR.Person[i]["��Ч����1"], rx, ry, C_RED, CC.FontSmall5, CC.FontName, 3)
						KungfuString(WAR.Person[i]["��Ч����0"], rx, ry, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
						yanshi = true
					--end
				else
					--�����壺 �����޶���ʱ����ʾ���ֵ�BUG
					if i~= WAR.CurID and theeft == -1 and ((WAR.Person[i]["��Ч����1"] ~= nil and WAR.Person[i]["��Ч����1"] ~= "  ") or (WAR.Person[i]["��Ч����2"] ~= nil and WAR.Person[i]["��Ч����2"] ~= "  ")  or (WAR.Person[i]["��Ч����3"] ~= nil and WAR.Person[i]["��Ч����3"] ~= "  ") ) then
						local dx = WAR.Person[i]["����X"] - x0
						local dy = WAR.Person[i]["����Y"] - y0
						local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
						local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2
						local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)

						ry = ry - hb

						KungfuString(WAR.Person[i]["��Ч����3"], rx, ry, C_WHITE, CC.FontSmall5, CC.FontName, 1)
						KungfuString(WAR.Person[i]["��Ч����2"], rx, ry, C_GOLD, CC.FontSmall5, CC.FontName, 2)
						KungfuString(WAR.Person[i]["��Ч����1"], rx, ry, C_RED, CC.FontSmall5, CC.FontName, 3)
						KungfuString(WAR.Person[i]["��Ч����0"], rx, ry, C_ORANGE, CC.FontSmall5, CC.FontName, 4)
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
	Cls()	--��ʾ����ǰ��ն�����Ӱ

	--�޾Ʋ���������ʱ�ĵ�Ѫ��״̬��ʾ
	if HitXYNum > 0 then
		local clips = {}
		for i = 0, HitXYNum - 1 do
			local dx = HitXY[i][1] - x0
			local dy = HitXY[i][2] - y0
			local hb = GetS(JY.SubScene, HitXY[i][1], HitXY[i][2], 4)		--����

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

		local area = (clip.x2 - clip.x1) * (clip.y2 - clip.y1)		--�滭�ķ�Χ
		local surid = lib.SaveSur(minx, miny, maxx, maxy)		--�滭���

		--��ʾ����
		--�޾Ʋ�����һ����ʾ����״̬
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
						--�޾Ʋ������������ַ�������λ�ж��Ƿ�Ϊ��Ѫ
						if y == 3 and HitXY[j][y] ~= nil and string.sub(HitXY[j][y],1,1) == "-" then
							if CONFIG.HPDisplay == 1 then
								HP_Display_When_Hit(i) --�޾Ʋ�����ʵʱ��Ѫ
							end
							DrawString(clips[j].x1 - string.len(HitXY[j][y])*CC.DefaultFont/4, clips[j].y1 - y_off, HitXY[j][y], Color_Hurt1, CC.DefaultFont)
						else
							--�޾Ʋ�����˫����ʾ��ʱ����д��
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

	--������ָ�Ѫ��
	WAR.ShowHP = 1

	--�������
	for i = 0, HitXYNum - 1 do
		local id = GetWarMap(HitXY[i][1], HitXY[i][2], 2);
		WAR.Person[id]["��������"] = nil;
		WAR.Person[id]["��������"] = nil;
		WAR.Person[id]["��������"] = nil;
		WAR.Person[id]["�ж�����"] = nil;
		WAR.Person[id]["�ⶾ����"] = nil;
		WAR.Person[id]["���˵���"] = nil;
		WAR.Person[id]["Life_Before_Hit"] = 0;
	end

	--�����Ч����
	for i = 0, WAR.PersonNum - 1 do
		WAR.Person[i]["��Ч����"] = -1
		WAR.Person[i]["��Ч����0"] = nil
		WAR.Person[i]["��Ч����1"] = nil
		WAR.Person[i]["��Ч����2"] = nil
		WAR.Person[i]["��Ч����3"] = nil
		WAR.Person[i]["��Ч����4"] = nil
	end
	lib.SetClip(0, 0, 0, 0)
	WarDrawMap(0)
	ShowScreen()
end


---ִ��ҽ�ƣ��ⶾ�ö��������Ӻ������Զ�ҽ��Ҳ�ɵ���
function War_ExecuteMenu_Sub(x1, y1, flag, thingid)
	local pid = WAR.Person[WAR.CurID]["������"]
	local x0 = WAR.Person[WAR.CurID]["����X"]
	local y0 = WAR.Person[WAR.CurID]["����Y"]
	CleanWarMap(4, 0)
	WAR.ShowHP = 0
	WAR.Person[WAR.CurID]["�˷���"] = War_Direct(x0, y0, x1, y1)
	SetWarMap(x1, y1, 4, 1)
	local emeny = GetWarMap(x1, y1, 2)
	if emeny >= 0 then
		if flag == 1 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
			WAR.Person[emeny]["�ж�����"] = War_PoisonHurt(pid, WAR.Person[emeny]["������"])
			SetWarMap(x1, y1, 4, 5)
			WAR.Effect = 5
		elseif flag == 2 and WAR.Person[WAR.CurID]["�ҷ�"] == WAR.Person[emeny]["�ҷ�"] then
			WAR.Person[emeny]["�ⶾ����"] = ExecDecPoison(pid, WAR.Person[emeny]["������"])
			SetWarMap(x1, y1, 4, 6)
			WAR.Effect = 6
		elseif flag == 3 then
			--ҽ�������ж�
			if WAR.Person[WAR.CurID]["������"] == 0 and JY.Base["��׼"] == 8 then

			elseif WAR.Person[WAR.CurID]["�ҷ�"] == WAR.Person[emeny]["�ҷ�"] then
			  WAR.Person[emeny]["��������"] = ExecDoctor(pid, WAR.Person[emeny]["������"])
			  SetWarMap(x1, y1, 4, 4)
			  WAR.Effect = 4
			end
		--����
		elseif flag == 4 and WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[emeny]["�ҷ�"] then
			--�������߷�������
			if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and WAR.Person[emeny]["������"] == 27 then
				CleanWarMap(4, 0)
				local orid = WAR.CurID
				WAR.CurID = emeny

				WAR.Person[WAR.CurID]["�˷���"] = War_Direct(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], x0, y0)

				Cls()
				local KHZZ = {"��֪��"..JY.Person[0]["���2"],"��Ȼ�����Ū��","���ҵĿ�������"}

				for i = 1, #KHZZ do
					lib.GetKey()
					DrawString(-1, -1, KHZZ[i], C_GOLD, CC.Fontsmall)
					ShowScreen()
					Cls()
					lib.Delay(1000)
				end

				SetWarMap(x0, y0, 4, 1)

				WAR.Person[orid]["��������"] = (WAR.Person[orid]["��������"] or 0) + AddPersonAttrib(WAR.Person[orid]["������"], "����", -300)
				WAR.Person[orid]["�ж�����"] = (WAR.Person[orid]["�ж�����"] or 0) + AddPersonAttrib(WAR.Person[orid]["������"], "�ж��̶�", 100)
				WAR.TXXS[WAR.Person[orid]["������"]] = 1

				WAR.KHSZ = 1

				War_ShowFight(WAR.Person[WAR.CurID]["������"], 0, -1, 0, x0, y0, 35)

				WAR.KHSZ = 0

				WAR.CurID = orid
				return 1
			end
			if not match_ID(pid, 83) then
				--��������˺�����
				WAR.AQBS = math.random(3)
				--Ԭ��־�ý���׶�ض�����
				if match_ID(pid, 54) and thingid == 30 then
					WAR.AQBS = 3
				end
				WAR.Person[emeny]["��������"] = War_AnqiHurt(pid, WAR.Person[emeny]["������"], thingid, emeny)
				SetWarMap(x1, y1, 4, 2)
				WAR.Effect = 2
			end
		end
	end
	--����ҽ������ҽ��
	if flag == 3 and pid == 0 and JY.Base["��׼"] == 8 then
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if WAR.Person[WAR.CurID]["�ҷ�"] == WAR.Person[ep]["�ҷ�"] then
						WAR.Person[ep]["��������"] = ExecDoctor(pid, WAR.Person[ep]["������"])
						SetWarMap(ex, ey, 4, 4)
						WAR.Effect = 4
					end
				end
			end
		end
	end
	--���Ƕ��������϶������Ը��Լ��϶�
	if flag == 1 and pid == 0 and JY.Base["��׼"] == 9 then
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if (WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[ep]["�ҷ�"]) or ep == WAR.CurID then
						WAR.Person[ep]["�ж�����"] = War_PoisonHurt(pid, WAR.Person[ep]["������"])
						SetWarMap(ex, ey, 4, 5)
						WAR.Effect = 5
					end
				end
			end
		end
	end
	--������ʹ�ð���Ϊ7*7����
	if flag == 4 and match_ID(pid, 83) then
		--��������˺�����
		WAR.AQBS = math.random(3)
		for ex = x1 - 3, x1 + 3 do
			for ey = y1 - 3, y1 + 3 do
				SetWarMap(ex, ey, 4, 1)
				if GetWarMap(ex, ey, 2) ~= nil and GetWarMap(ex, ey, 2) > -1 then
					local ep = GetWarMap(ex, ey, 2)
					if WAR.Person[WAR.CurID]["�ҷ�"] ~= WAR.Person[ep]["�ҷ�"] then
						WAR.Person[ep]["��������"] = War_AnqiHurt(pid, WAR.Person[ep]["������"], thingid, ep)
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
		--WAR.Person[i]["����"] = 0
	--end
	if flag == 4 then
		if emeny >= 0 or match_ID(pid, 83) then
			instruct_32(thingid, -1)
			return 1
		else
			return 0
		end
	else
		WAR.Person[WAR.CurID]["����"] = WAR.Person[WAR.CurID]["����"] + 1
		AddPersonAttrib(pid, "����", -2)
	end

	if inteam(pid) then
		AddPersonAttrib(pid, "����", -4)
	end
	return 1
end

--�޾Ʋ���������󣬻滭��̬���������ж�
function DrawTimeBar2()
	local x1,x2,y = CC.ScreenW * 1 / 2 - 34, CC.ScreenW * 19 / 20 - 2, CC.ScreenH/10 + 29
	local draw = false

	--�������ǹ̶��ģ�ֻ��Ҫ����һ�ξͿ�����
	--�޾Ʋ���������ҲҪ�ж��Ƿ�����Ҫdraw��������Ҫ�򲻼���
	local drawframe = false
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			if WAR.Person[i].TimeAdd < 0 then
				drawframe =  true
				break
			end
		end
	end
	if drawframe == true then
		DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
		DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
		DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
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
			local pid = WAR.Person[i]["������"];
			--�����ж������Ƿ����
			if WAR.Person[i]["����"] == false then
				--����TimeAddС��0������λ��Ҫ���٣���ֵΪ��������
				if WAR.Person[i].TimeAdd < 0 then
					draw = true
					--������20Ϊ��λѭ�����ӣ����ӵ�����0ʱ���ж������ٳ�������ֹͣ���ټ���λ��
					WAR.Person[i].TimeAdd = WAR.Person[i].TimeAdd + 20
					if WAR.Person[i].TimeAdd > 0 then
						WAR.Person[i].TimeAdd = 0;
					end
					--�������ļ���λ��û�дﵽ-500�������20����-500����
					if WAR.Person[i].Time > -500 then
						--��������٤���򲻻����300
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
					--�������ļ���λ���Ѿ��ﵽ-500������λ�ò��ټ��٣�����ת��Ϊ����
					else
						if JY.Person[pid]["���˳̶�"] < 100 then
							AddPersonAttrib(pid, "���˳̶�", math.random(3))
						end
					end
					if WAR.Person[i].Time <= -500 and PersonKF(pid, 100) then	--�������칦�󣬵�������ɱ��-500������ֱ����0
						JY.Person[pid]["���˳̶�"] = 0;
					end
				--����0������λ��Ҫ���ӣ�
				elseif WAR.Person[i].TimeAdd > 0 then
					draw = true
					--������20Ϊ��λѭ�����٣����ٵ�����0ʱ���ж������ٳ�������ֹͣ���Ӽ���λ��
					WAR.Person[i].TimeAdd = WAR.Person[i].TimeAdd - 20
					--����ļ���λ����20Ϊ��λ���ӣ��������λ�ó���995����ǿ�ƶ�Ϊ995
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

--���Ƽ�����
function DrawTimeBar()

	local x1,x2,y = CC.ScreenW * 1 / 2 - 34, CC.ScreenW * 19 / 20 - 2, CC.ScreenH/10 + 29
	local xunhuan = true

	--�������ǹ̶��ģ�ֻ��Ҫ����һ�ξͿ�����
	DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
	DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
	DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
	lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
	lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)

	lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
	local surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)	--�޾Ʋ������޸�ɱ��-500������Сͷ��ˢ������
	while xunhuan do
		if JY.Restart == 1 then
			break
		end
		for i = 0, WAR.PersonNum - 1 do
			if WAR.Person[i]["����"] == false then
				local jqid = WAR.Person[i]["������"]
				local jq = WAR.Person[i].TimeAdd	--���Ｏ���ٶ�
				--�޾Ʋ�����ÿ25������-1������ÿ25���ж�-1�����������NPCһ��
				local ns_factor = math.modf(JY.Person[jqid]["���˳̶�"] / 25)
				local zd_factor = math.modf(JY.Person[jqid]["�ж��̶�"] / 25)
				--�����ж��������Ӽ���
				if jqid == 0 and JY.Base["��׼"] == 9 then
					zd_factor = -(zd_factor*2)
				end
				--����Ҳ����
				local bf_factor = 0;
				if JY.Person[jqid]["����̶�"] >= 50 then
					bf_factor = 6
				elseif JY.Person[jqid]["����̶�"] > 0 then
					bf_factor = 3
				end
				--��̫������ټ��ټ�����һ�����1%
				local HTC_tq = 0
				if WAR.QYZT[jqid] ~= nil then
					HTC_tq = jq * 0.01 * WAR.QYZT[jqid]
				end
				--����ˮ��������״̬Ӱ��
				if match_ID(jqid, 118) == false then
					jq = jq - ns_factor - zd_factor - bf_factor - HTC_tq
				end
				if jq < 0 then
					jq = 0
				end
				if WAR.LQZ[jqid] == 100 then
					if Curr_QG(jqid,150) then	--�˹�˲Ϣǧ���ŭ4������
						jq = jq * 4
					else
						jq = jq * 3				--��ŭ3������
					end
				end
				--��˯�ĵ��ˣ��޷�����
				if WAR.CSZT[jqid] == 1 then
					jq = 0
				--������ʤ���л��е��ˣ��޷�����
				elseif WAR.WZSYZ[jqid] ~= nil then
					jq = 0
					WAR.WZSYZ[jqid] = WAR.WZSYZ[jqid] - 1
					if WAR.WZSYZ[jqid] < 1 then
						WAR.WZSYZ[jqid] = nil
					end
				--����ĵ��ˣ��޷�����				
				elseif WAR.LRHF[jqid] ~= nil then
					jq = 0
					WAR.LRHF[jqid] = WAR.LRHF[jqid] - 1
					if WAR.LRHF[jqid] < 1 then
						WAR.LRHF[jqid] = nil
					end
				--û�з�Ѩ������£����Լ���
				elseif WAR.FXDS[jqid] == nil then
					--ŷ���������
					if match_ID(jqid, 60) and (math.random(10) == 8 or math.random(10) == 8) then
						jq = jq + math.random(10, 30);
					end
					if WAR.LSQ[jqid] ~= nil then	--������ȭ���У���������20ʱ��
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
				--����Ѩ�Ļ������Ἧ����ʱ����ٷ�Ѩ
				else
					WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1

					--�׽ ��Ѩ�ظ�+1
					if PersonKF(jqid, 108) then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end

					--����+��Ů����Ѩ�ظ�+1
					if PersonKF(jqid, 100) and PersonKF(jqid, 154) then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end

					--����7ʱ������Ѩ
					--�������˻������ѧ�������
					if Curr_NG(jqid, 106) and (JY.Person[jqid]["��������"] == 1 or (jqid == 0 and JY.Base["��׼"] == 6)) then
						if WAR.JYFX[jqid] == nil then
							WAR.JYFX[jqid] = 1;
						elseif WAR.JYFX[jqid] < 7 then
							WAR.JYFX[jqid] = WAR.JYFX[jqid] + 1;
						else
							WAR.JYFX[jqid] = nil;
							WAR.FXDS[jqid] = 0;
						end
					end

					--��ŭʱ��Ѩ�ٶȼӱ�
					if WAR.LQZ[jqid] == 100 then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end
					if WAR.FXDS[WAR.Person[i]["������"]] < 1 then
						WAR.FXDS[WAR.Person[i]["������"]] = nil
					end
				end

				--�����񹦻���
				--ѧ��������������ڻ������
				if PersonKF(jqid, 106) and (JY.Person[jqid]["��������"] == 1 or (jqid == 0 and JY.Base["��׼"] == 6)) then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 9
				end

				--�����񹦻�Ѫ
				--ѧ��������������ڻ������
				if PersonKF(jqid, 107) and (JY.Person[jqid]["��������"] == 0 or (jqid == 0 and JY.Base["��׼"] == 6)) then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 2
				end

				--���������Ѫ
				--�������˻������ѧ�������
				if Curr_NG(jqid, 107) and (JY.Person[jqid]["��������"] == 0 or (jqid == 0 and JY.Base["��׼"] == 6)) and inteam(jqid) then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 2
				end

				--���칦��Ѫ����
				if PersonKF(jqid, 100) then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 4
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 2
				end

				--�׽����
				if PersonKF(jqid, 108) then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 6
				end

				
				--JY.Person[jqid]["����"] = JY.Person[jqid]["����"] - 100 + JY.Person[jqid]["����"]
				--[[�ҷ��˹�ʱ����������500��ͣ��
				if JY.Person[jqid]["�����ڹ�"] > 0 and JY.Person[jqid]["����"] < 500 and inteam(jqid) then
					JY.Person[jqid]["�����ڹ�"] = 0
				end

				--�˹�ʱ����������10��ͣ��
				if JY.Person[jqid]["�����ڹ�"] > 0 and JY.Person[jqid]["����"] < 10 and inteam(jqid) then
					JY.Person[jqid]["�����ڹ�"] = 0
				end

				--�ҷ��˹�����
				if JY.Person[jqid]["�����ڹ�"] > 0 and inteam(jqid) then
					--��������
					if JY.Person[jqid]["�����ڹ�"] == JY.Person[jqid]["�츳�ڹ�"] then
						--���Ѻ�6�����ǲ���
						if jqid ~= 0 then
							JY.Person[jqid]["����"] = JY.Person[jqid]["����"] - 6
						end
					--���������ڣ���9
					else
						JY.Person[jqid]["����"] = JY.Person[jqid]["����"] - 9
					end
				end]]

				--��������ɳ����ÿʱ���1%Ѫ
				if match_ID(jqid, 47) and WAR.JYZT[jqid]~=nil then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] - math.modf(JY.Person[jqid]["�������ֵ"]*0.01)
					if JY.Person[jqid]["����"] < 1 then
						JY.Person[jqid]["����"] = 0
						WAR.Person[WAR.CurID]["����"] = true
						WarSetPerson()
						Cls()
						ShowScreen()
						break
					end
				end

				--��ȼ��ÿʱ����ʧ1%��ǰѪ��
				if WAR.JHLY[jqid] ~= nil then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] - math.modf(JY.Person[jqid]["����"]*0.01)

					if JY.Person[jqid]["����"] < 1 then
						JY.Person[jqid]["����"] = 1
					end
					WAR.JHLY[jqid] = WAR.JHLY[jqid] - 1

					if WAR.JHLY[jqid] < 1 then
						WAR.JHLY[jqid] = nil
					end
				end

				--�������ʯ��٣�100ʱ��
				if WAR.YSJF[jqid] ~= nil then
					WAR.YSJF[jqid] = WAR.YSJF[jqid] - 1

					if WAR.YSJF[jqid] < 1 then
						WAR.YSJF[jqid] = nil
					end
				end

				--���ƾ����еĵ��ˣ��ڹ�ͣ��50ʱ��
				if WAR.PJZT[jqid] ~= nil then
					WAR.PJZT[jqid] = WAR.PJZT[jqid] - 1
					if WAR.PJZT[jqid] < 1 then
						WAR.PJZT[jqid] = nil
						JY.Person[jqid]["�����ڹ�"] = WAR.PJJL[jqid]
						WAR.PJJL[jqid] = nil
					end
				end

				--����״̬������󣬵���״̬�ָ�
				if WAR.HLZT[jqid] ~= nil then
					WAR.HLZT[jqid] = WAR.HLZT[jqid] - 1
					if WAR.HLZT[jqid] < 1 then
						WAR.HLZT[jqid] = nil
						WAR.Person[i]["�ҷ�"] = false
					end
				end

				--����״̬
				if WAR.XRZT[jqid] ~= nil then
					WAR.XRZT[jqid] = WAR.XRZT[jqid] - 1
					if WAR.XRZT[jqid] < 1 then
						WAR.XRZT[jqid] = nil
					end
				end

				--�޾Ʋ��������˸�󡹦ʱ������ŭ��
				if Curr_NG(jqid, 95) then
					if WAR.LQZ[jqid] == nil then
						WAR.LQZ[jqid] = 1
					elseif WAR.LQZ[jqid] < 100 then
						WAR.LQZ[jqid] = WAR.LQZ[jqid] + 1
						if WAR.LQZ[jqid] == 100 then
							--�������ܣ������ط�������Ϊ��
							local s = WAR.CurID
							local say = "ŭ������"
							local ani_num = 6
							WAR.CurID = i
							if match_ID(jqid, 27) then
								say = "�����ط�������Ϊ��"
								ani_num = 7
							end
							Cls()
							lib.SetClip(0, CC.ScreenH/4 + 20, CC.ScreenW, CC.ScreenH)
							CurIDTXDH(WAR.CurID, ani_num, 1, say)
							WAR.CurID = s
							--�ָ�֮ǰ�Ļ���
							DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
							DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
							DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
							lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
							lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
							lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
							surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						end
					end
				end

				--�޾Ʋ�������Զɽʱ������ŭ��
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
							CurIDTXDH(WAR.CurID, 6, 1, "ŭ������")
							WAR.CurID = s
							--�ָ�֮ǰ�Ļ���
							DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
							DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
							DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
							lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
							lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
							lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
							surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						end
					end
				end

				--��ɽͯ�ѣ�ת˲����
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
						CurIDTXDH(WAR.CurID, 104, 1, "���յ�ָ�ϡ�ɲ�Ƿ���", PinkRed)
						WAR.CurID = s
						--�ָ�֮ǰ�Ļ���
						DrawBox_1(x1 - 3, y, x2 + 3, y + 3, C_ORANGE)
						DrawBox_1(x1 - (x2 - x1) / 2, y, x1 - 3, y + 3, C_RED)
						DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
						lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
						lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
						lib.SetClip(x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						surid = lib.SaveSur( x1 - (x2-x1)/2-100, 0, CC.ScreenW, CC.ScreenH/4 + 50)
						JY.Person[jqid]["����"] = JY.Person[jqid]["�������ֵ"]
						JY.Person[jqid]["����"] = JY.Person[jqid]["�������ֵ"]
						JY.Person[jqid]["����"] = 100
						JY.Person[jqid]["�ж��̶�"] = 0
						JY.Person[jqid]["���˳̶�"] = 0
						JY.Person[jqid]["����̶�"] = 0
						JY.Person[jqid]["���ճ̶�"] = 0
						--��Ѫ
						if WAR.LXZT[jqid] ~= nil then
							WAR.LXZT[jqid] = nil
						end
						--��Ѩ
						if WAR.FXDS[jqid] ~= nil then
							WAR.FXDS[jqid] = nil
						end
					end
				end

				--[[�������ߣ��ָ�
				if WAR.ZDDH == 54 and JY.Person[27]["Ʒ��"] == 20 and WAR.MCRS == 1 and jqid == 27 then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 5
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 10
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + 1
					JY.Person[jqid]["�ж��̶�"] = JY.Person[jqid]["�ж��̶�"] - 1
					JY.Person[jqid]["���˳̶�"] = JY.Person[jqid]["���˳̶�"] - 1
					JY.Person[jqid]["����̶�"] = JY.Person[jqid]["����̶�"] - 1
					JY.Person[jqid]["���ճ̶�"] = JY.Person[jqid]["���ճ̶�"] - 1
					--��Ѫ
					if WAR.LXZT[jqid] ~= nil then
						WAR.LXZT[jqid] = WAR.LXZT[jqid] - 1
					end
					--��Ѩ
					if WAR.FXDS[jqid] ~= nil then
						WAR.FXDS[jqid] = WAR.FXDS[jqid] - 1
					end
				end

				--����ҽ����Ѫ�ڣ������ˣ����ж�
				if jqid == 0 and JY.Base["��׼"] == 8 then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + math.random(5);
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + math.random(5);
					JY.Person[jqid]["�ж��̶�"] = JY.Person[jqid]["�ж��̶�"] - math.random(5);
					JY.Person[jqid]["���˳̶�"] = JY.Person[jqid]["���˳̶�"] - math.random(5);
				end

				--����ʱ�������ж�
				if jqid == 0 and JY.Base["��׼"] == 9 then
					JY.Person[jqid]["�ж��̶�"] = JY.Person[jqid]["�ж��̶�"] + math.random(5)
					if JY.Person[jqid]["�ж��̶�"] > 100 then
						JY.Person[jqid]["�ж��̶�"] = 100
					end
				end]]

				--���Ʊ���ʱ�����
				if WAR.QYBY[jqid] ~= nil then
					WAR.QYBY[jqid] = WAR.QYBY[jqid] - 1
					if WAR.QYBY[jqid] < 1 then
						WAR.QYBY[jqid] = nil
					end
				end

				--����̩ɽ��ʹ�ú�20ʱ��������
				if WAR.TSSB[jqid] ~= nil then
					WAR.TSSB[jqid] = WAR.TSSB[jqid] - 1
					if WAR.TSSB[jqid] < 1 then
						WAR.TSSB[jqid] = nil
					end
				end

				--����ҵ��״̬������ʹ�õ�����һ���������30ʱ��
				if WAR.WMYH[jqid] ~= nil then
					WAR.WMYH[jqid] = WAR.WMYH[jqid] - 1
					if WAR.WMYH[jqid] < 1 then
						WAR.WMYH[jqid] = nil
					end
				end

				--�����壺���ѹ�ָ���ʱ���ж�
				if WAR.L_WNGZL[jqid] ~= nil and WAR.L_WNGZL[jqid] > 0 then
					JY.Person[jqid]["�ж��̶�"] = JY.Person[jqid]["�ж��̶�"] + 1
					WAR.L_WNGZL[jqid] = WAR.L_WNGZL[jqid] -1;

					if WAR.L_WNGZL[jqid] <= 0 then
						WAR.L_WNGZL[jqid] = nil;
					end
				end

				--brolycjw������ţָ�ÿ��ʱ��ظ�1%Ѫ
				if WAR.L_HQNZL[jqid] ~= nil and WAR.L_HQNZL[jqid] > 0 then
					JY.Person[jqid]["����"] = JY.Person[jqid]["����"] + math.modf(JY.Person[jqid]["�������ֵ"]/100);
					if JY.Person[jqid]["���˳̶�"] > 50 then
						JY.Person[jqid]["���˳̶�"] = JY.Person[jqid]["���˳̶�"] - 2;
					else
						JY.Person[jqid]["���˳̶�"] = JY.Person[jqid]["���˳̶�"] - 1;
					end
					WAR.L_HQNZL[jqid] = WAR.L_HQNZL[jqid] -1;
					if WAR.L_HQNZL[jqid] <= 0 then
						WAR.L_HQNZL[jqid] = nil;
					end
				end

				--�޾Ʋ���������������ȡλ��
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

		local warStatus = War_isEnd2()   --ս���Ƿ������   0������1Ӯ��2��
		if 0 < warStatus then
			break;
		end

		DrawTimeBar_sub(x1, x2, nil, 0)
		ShowScreen(1)
		WAR.SXTJ = WAR.SXTJ + 1
		--�޾Ʋ�������ʱ����ʱ����ʱ�򣬾�ʱ��ļ�����
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
		lib.Delay(10) -- �޾Ʋ����������������ٶ�	

		--���������а��ո��س�ֹͣ�Զ�
		local keypress = lib.GetKey()
		if (keypress == VK_SPACE or keypress == VK_RETURN) then
			if WAR.AutoFight == 1 then
				WAR.AutoFight = 0
			end
		end

		lib.LoadSur(surid, x1 - ((x2 - x1) / 2)-100, 0)	--�޾Ʋ������޸�ɱ��-500������Сͷ��ˢ������
	end

	--ʱ���������
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["����"] == false then
			WAR.Person[i].TimeAdd = 0
			local jqid=WAR.Person[i]["������"]

			--�ж��Ƿ����������ݷ�Χ֮��
			if JY.Person[jqid]["�ж��̶�"] < 0 then
				JY.Person[jqid]["�ж��̶�"] = 0;
			end
			if JY.Person[jqid]["���˳̶�"] < 0 then
				JY.Person[jqid]["���˳̶�"] = 0;
			end
			if JY.Person[jqid]["����̶�"] < 0 then
				JY.Person[jqid]["����̶�"] = 0;
			end
			if JY.Person[jqid]["���ճ̶�"] < 0 then
				JY.Person[jqid]["���ճ̶�"] = 0;
			end
			if JY.Person[jqid]["�������ֵ"] < JY.Person[jqid]["����"] then
				JY.Person[jqid]["����"] = JY.Person[jqid]["�������ֵ"]
			end
			if JY.Person[jqid]["�������ֵ"] < JY.Person[jqid]["����"] then
				JY.Person[jqid]["����"] = JY.Person[jqid]["�������ֵ"]
			end
			if JY.Person[jqid]["����"] > 100 then
				JY.Person[jqid]["����"] = 100
			end
		end
	end

	WAR.ZYHBP = -1
	lib.SetClip(0, 0, 0, 0)
	lib.FreeSur(surid)
end

--�滭���弯����
function DrawTimeBar_sub(x1, x2, y, flag)

	--�޾Ʋ������滭����������������ʾ
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
		DrawString(x2 + 10, y - 20, "ʱ��", C_WHITE, CC.FontSMALL)
		lib.FillColor(x1+1, y+1, x1+90, y+3,C_ORANGE)
		lib.FillColor(x1-94, y+1, x1-6, y+3,C_RED)
	end

	for i = 0, WAR.PersonNum - 1 do
		if not WAR.Person[i]["����"] then
			--�޾Ʋ�����������������ʾ������ɹ�1000
			if WAR.Person[i].Time > 1001 then
				WAR.Person[i].Time = 1001
			end
			local id = WAR.Person[i]["������"]
			local cx = x1 + math.modf(WAR.Person[i].Time*(x2 - x1)/1000)
			local headid = WAR.tmp[5000+i];
			if headid == nil then
				headid = JY.Person[id]["ͷ�����"]
			end
			local w, h = limitX(CC.ScreenW/25,12,35),limitX(CC.ScreenW/25,12,35)
			local jq_color = C_WHITE
			if JY.Person[id]["�ж��̶�"] == 100 then
				jq_color = RGB(56, 136, 36)
			elseif JY.Person[id]["�ж��̶�"] >= 50 then
				jq_color = RGB(120, 208, 88)
			end
			if WAR.LQZ[id] == 100 then
				jq_color = C_RED
			end
			if WAR.Person[i]["�ҷ�"] then
				drawname(cx, 1, id, CC.FontSmall)
				lib.LoadPNG(99, headid*2, cx - w / 2, y - h - 4, 1, 0)
				DrawString(cx-21, y-10-9, string.format("%3d",WAR.JQSDXS[id]), jq_color, CC.FontSMALL)	--�����ٶ�
				if JY.Person[id]["���ճ̶�"] ~= 0 then
					DrawString(cx, y-10-33, string.format("%3d",JY.Person[id]["���ճ̶�"]), C_ORANGE, CC.FontSMALL)	--������ֵ
				end
				if WAR.FXDS[id] ~= nil and WAR.FXDS[id] ~= 0 then
					DrawString(cx-21, y-10-33, string.format("%3d",WAR.FXDS[id]), C_GOLD, CC.FontSMALL)	--��Ѩ��ֵ
				end
			else
				drawname(cx, y+h, id, CC.FontSmall)
				lib.LoadPNG(99, headid*2, cx - w / 2, y + 6, 1, 0)
				DrawString(cx-21, y+h-9, string.format("%3d",WAR.JQSDXS[id]), jq_color, CC.FontSMALL)	--�����ٶ�
				if JY.Person[id]["���ճ̶�"] ~= 0 then
					DrawString(cx, y+h-33, string.format("%3d",JY.Person[id]["���ճ̶�"]), C_ORANGE, CC.FontSMALL)	--������ֵ
				end
				if WAR.FXDS[id] ~= nil and WAR.FXDS[id] ~= 0 then
					DrawString(cx-21, y+h-33, string.format("%3d",WAR.FXDS[id]), C_GOLD, CC.FontSMALL)	--��Ѩ��ֵ
				end
			end
		end
	end
	DrawString(x2 + 10, y , WAR.SXTJ, C_GOLD, CC.FontSMALL)
end

--�滭�������ϵ�����
function drawname(x, y, id, size)
	local name = JY.Person[id]["����"]
	local color = C_WHITE
	--������ɫ���������˱仯
	if JY.Person[id]["���˳̶�"] > JY.Person[id]["����̶�"] then
		if JY.Person[id]["���˳̶�"] > 99 then
			color = RGB(232, 32, 44)
		elseif JY.Person[id]["���˳̶�"] > 66 then
			color = RGB(244, 128, 32)
		elseif JY.Person[id]["���˳̶�"] > 33 then
			color = RGB(236, 200, 40)
		end
	else
		if JY.Person[id]["����̶�"] >= 50 then
			color = M_RoyalBlue
		elseif JY.Person[id]["����̶�"] > 0 then
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

--�ж�����֮��ľ���
function RealJL(id1, id2, len)
	if not len then
		len = 1
	end
	local x1, y1 = WAR.Person[id1]["����X"], WAR.Person[id1]["����Y"]
	local x2, y2 = WAR.Person[id2]["����X"], WAR.Person[id2]["����Y"]
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

--�书��Χ
function WugongArea(wugong, level)
  --�޾Ʋ���������˵��
  --m1Ϊ�ƶ���Χб�����죺
	--0������Ϊֱ�߾���-1��1��������ֱ�߾��룬2������Ϊ0 3���ƶ���Χ�̶�Ϊ������Χ8��
  --m2Ϊ�ƶ���Χֱ�����죻
	--���ּ������������
  --a1Ϊ������Χ���ͣ�
	--0���㹥��1��ʮ�֣�2�����Σ�3���湥��5��ʮ�֣�6�����֣�7�����֣�8���d�֣�9���e�֣�10��ֱ�ߣ�11�������ǣ�12�������ǣ�13������
  --a2Ϊ������Χ���Ⱦ��룺
	--0���㹥������0ʱ������ = a2
	local m1, m2, a1, a2 = nil, nil, nil, nil
	if JY.Wugong[wugong]["������Χ"] == -1 then
		return JY.Wugong[wugong]["������1"], JY.Wugong[wugong]["������2"], JY.Wugong[wugong]["δ֪1"], JY.Wugong[wugong]["δ֪2"], JY.Wugong[wugong]["δ֪3"], JY.Wugong[wugong]["δ֪4"], JY.Wugong[wugong]["δ֪5"]
	end
	--0��ȭָ
	--1����
	--2����
	--3����
	--4��ǹ
	--5������
	local fightscope = JY.Wugong[wugong]["������Χ"]
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

--��CC���ж������Ƿ�Ϊ���ѣ������ڲ��ڶ�
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

--�ж������Ƿ���ĳ���书
function NewPersonKF(p, kf)
	for i = 1, CC.Kungfunum do
		if JY.Person[p]["�书" .. i] <= 0 then
			return false;
		elseif JY.Person[p]["�书" .. i] == kf then
			return true
		end
	end
	return false
end

--�ϴ���
function PersonKF(p, kf)
	return false
end

function PersonKFJ(p, kf)
	return false
end

--�жϴ�������
function myrandom(p, id)
	--̫����+20
	if PersonKF(id, 102) then
		p = p + 20
	end
	--����Խ�ͣ�����Խ�ߣ����10
	p = p + math.modf((JY.Person[id]["�������ֵ"]/JY.Person[id]["Ѫ������"] - JY.Person[id]["����"]/JY.Person[id]["Ѫ������"])/100 + 1);

	--����Խ�ߣ�����Խ�ߣ����10
	p = p + math.modf(JY.Person[id]["����"] / 10)

	--�ֳ�Ӣ+10
	if match_ID(id, 605) then
		p = p + 10
	end

	--�����߻�+20
	if WAR.tmp[1000 + id] == 1 then
		p = p + 20
	end

	--ÿ25��ʵս+1������20
	local jp = math.modf(JY.Person[id]["ʵս"] / 25 + 1)
	if jp > 20 then
		jp = 20
	end
	p = p + jp

	--ÿ500����+1�����20
	p = p + limitX(math.modf(JY.Person[id]["����"] / 500), 0, 20)

	--ÿ50�㹥����+1�����10
	p = p + limitX(math.modf(JY.Person[id]["������"] / 50), 0, 10)

	--ÿ50�������+1�����10
	p = p + limitX(math.modf(JY.Person[id]["������"] / 50), 0, 10)

	--ÿ50���Ṧ+1�����10
	p = p + limitX(math.modf(JY.Person[id]["�Ṧ"] / 50), 0, 10)

	--�����ж�����Ϊһ��
	local times = 1
	--������ҷ�
	if inteam(id) then
		--�ҷ��������Ӽ���
		p = p + JY.Base["��������"]
		--50%���ʶ����ж�
		if math.random(2) == 2 then
			times = 2
		end
		--ʯ����ض������ж�
		if match_ID(id, 38) and times == 1 then
			times = 2
		end
	--NPCĬ��Ϊ�����ж��Ҽ���+60
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


--�Զ�ѡ�����
function War_AutoSelectEnemy()
	local enemyid = War_AutoSelectEnemy_near()
	WAR.Person[WAR.CurID]["�Զ�ѡ�����"] = enemyid
	return enemyid
end

--ѡ���������
function War_AutoSelectEnemy_near(id)
	if id == nil then
		id = WAR.CurID
	end
	War_CalMoveStep(id, 100, 1)			--���ÿ��λ�õĲ���
	local maxDest = math.huge
	local nearid = -1
	for i = 0, WAR.PersonNum - 1 do		--������������ĵ���
		if WAR.Person[id]["�ҷ�"] ~= WAR.Person[i]["�ҷ�"] and WAR.Person[i]["����"] == false then
			local step = GetWarMap(WAR.Person[i]["����X"], WAR.Person[i]["����Y"], 3)
			if step < maxDest then
				nearid = i
				maxDest = step
			end
		end
	end
	return nearid
end

--ս���м���������
function NewWARPersonZJ(id, dw, x, y, life, fx)
	WAR.Person[WAR.PersonNum]["������"] = id
	WAR.Person[WAR.PersonNum]["�ҷ�"] = dw
	WAR.Person[WAR.PersonNum]["����X"] = x
	WAR.Person[WAR.PersonNum]["����Y"] = y
	WAR.Person[WAR.PersonNum]["����"] = life
	WAR.Person[WAR.PersonNum]["�˷���"] = fx
	WAR.Person[WAR.PersonNum]["��ͼ"] = WarCalPersonPic(WAR.PersonNum)
	lib.PicLoadFile(string.format(CC.FightPicFile[1], JY.Person[id]["ͷ�����"]), string.format(CC.FightPicFile[2], JY.Person[id]["ͷ�����"]), 4 + WAR.PersonNum)
	SetWarMap(x, y, 2, WAR.PersonNum)
	SetWarMap(x, y, 5, WAR.Person[WAR.PersonNum]["��ͼ"])
	WAR.PersonNum = WAR.PersonNum + 1
end

--�޾Ʋ������ж��ϻ��õĺ���
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

--�޾Ʋ�����������ܷ������˺��ж�
function First_strike_dam_DG(pid, eid)
	local dam;
	local YJ_dif = (TrueYJ(pid)*2 - TrueYJ(eid))*5/1000
	dam = (JY.Person[pid]["������"]*1.5-JY.Person[eid]["������"])+(JY.Person[pid]["��ѧ��ʶ"]*1.5-JY.Person[eid]["��ѧ��ʶ"])+(getnl(pid)/50*1.5-getnl(eid)/50)
	dam = math.modf(dam * YJ_dif)
	return dam
end

--�˺���ʽ�е���������ǰ����������������������
function getnl(id)
	return (JY.Person[id]["����"] * 2 + JY.Person[id]["�������ֵ"]) / 3
end

--�޾Ʋ�����Ѫ����������
function Health_in_Battle()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["������"]
		--��һ�����������ظ�����
		if JY.Person[pid]["Ѫ������"] > 1 and WAR.HP_Bonus_Count[pid] == nil then
			JY.Person[pid]["�������ֵ"] = JY.Person[pid]["�������ֵ"] * JY.Person[pid]["Ѫ������"]
			JY.Person[pid]["����"] = JY.Person[pid]["����"] * JY.Person[pid]["Ѫ������"]
			WAR.HP_Bonus_Count[pid] = 1
		end
	end
end

--�޾Ʋ�����Ѫ����ԭ����
function Health_in_Battle_Reset()
	for i = 0, WAR.PersonNum - 1 do
		local pid = WAR.Person[i]["������"]
		if JY.Person[pid]["Ѫ������"] > 1 and WAR.HP_Bonus_Count[pid] ~= nil then
			JY.Person[pid]["�������ֵ"] = JY.Person[pid]["�������ֵ"] / JY.Person[pid]["Ѫ������"]
			WAR.HP_Bonus_Count[pid] = nil
		end
	end
end

--�޾Ʋ������ȴ�ָ��
function War_Wait()
	Cls()
  	CurIDTXDH(WAR.CurID, 72, 1, "�Ż�����", LightGreen, 15)
	PushBack(WAR.CurID, 1)
	local id = WAR.Person[WAR.CurID]["������"]
	WAR.Wait[id] = 1
  	return 1;
end

--�޾Ʋ���������
function War_Retreat()
	local id = WAR.Person[WAR.CurID]["������"]
	local r = JYMsgBox(JY.Person[id]["����"], "ȷ��Ҫ�ҳ�����", {"��","��"}, 2, WAR.tmp[5000+WAR.CurID])
	if r == 2 then
		WAR.Person[WAR.CurID]["����"] = true
		return 1;
	end
end

--�޾Ʋ�������̬Ѫ����ʾ
function HP_Display_When_Idle()
    local x0 = WAR.Person[WAR.CurID]["����X"];
    local y0 = WAR.Person[WAR.CurID]["����Y"];
	for k = 0, WAR.PersonNum - 1 do
		local tmppid = WAR.Person[k]["������"]
		if WAR.Person[k]["����"] == false then
			local dx = WAR.Person[k]["����X"] - x0
			local dy = WAR.Person[k]["����Y"] - y0

			local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

			local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
					ry = ry - hb - CC.YScale*7

			local pid = WAR.Person[k]["������"]

			local Color = RGB(238,44, 44)
			--local Color1 = RGB(30, 144, 255)

			local HP_MAX = JY.Person[pid]["�������ֵ"]

			local Current_HP = JY.Person[pid]["����"]

			if Current_HP < 0 then
				Current_HP = 0
			end

			--�Ѿ�NPC��ʾΪ��ɫѪ��
			if WAR.Person[k]["�ҷ�"] == true then
				Color = RGB(0, 238, 0)
			end

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9,grey21)	--����

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx-CC.XScale*1.4+(Current_HP/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --����

			DrawBox3(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9, C_BLACK)
		end
	end
end

--�޾Ʋ����������Ѫ��ʾ
function HP_Display_When_Hit(ssxx)
    local x0 = WAR.Person[WAR.CurID]["����X"];
    local y0 = WAR.Person[WAR.CurID]["����Y"];
	--��Ѫ������ʾ			
	ssxx = ssxx - 4
	for k = 0, WAR.PersonNum - 1 do
		local tmppid = WAR.Person[k]["������"]
		--Ѫ���б仯����ʾ
		if WAR.Person[k]["����"] == false and WAR.Person[k]["��������"] ~= nil and WAR.Person[k]["��������"] ~= 0 then
			local dx = WAR.Person[k]["����X"] - x0
			local dy = WAR.Person[k]["����Y"] - y0

			local rx = CC.XScale * (dx - dy) + CC.ScreenW / 2
			local ry = CC.YScale * (dx + dy) + CC.ScreenH / 2

			local hb = GetS(JY.SubScene, dx + x0, dy + y0, 4)
					ry = ry - hb - CC.YScale*7

			local pid = WAR.Person[k]["������"]

			local Color = RGB(238,44, 44)
			--local Color1 = RGB(30, 144, 255)

			--�����Ѫ
			local HP_MAX = JY.Person[pid]["�������ֵ"]

			local HP_AfterHit = JY.Person[pid]["����"]

			if HP_AfterHit < 0 then
				HP_AfterHit = 0
			end

			local HP_BeforeHit = WAR.Person[k]["Life_Before_Hit"] or 0

			local HP_Loss = HP_BeforeHit - HP_AfterHit

			local Gradual_HP_Loss;
			local Gradual_HP_Display;

			Gradual_HP_Loss = HP_Loss*(ssxx/11)
			Gradual_HP_Display = HP_BeforeHit - Gradual_HP_Loss


			--�Ѿ�NPC��ʾΪ��ɫѪ��
			if WAR.Person[k]["�ҷ�"] == true then
				Color = RGB(0, 238, 0)
			end

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9,grey21)	--����

			lib.FillColor(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx-CC.XScale*1.4+(HP_AfterHit/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --����

			--��Ѫ��ʾ
			if HP_Loss > 0 then
				lib.FillColor(rx-CC.XScale*1.4+(HP_AfterHit/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*20/9, rx-CC.XScale*1.4+(Gradual_HP_Display/HP_MAX)*(2.8*CC.XScale), ry-CC.YScale*15/9, Color)  --ʧȥ����
			end

			DrawBox3(rx-CC.XScale*1.4, ry-CC.YScale*20/9, rx+CC.XScale*1.4, ry-CC.YScale*15/9, C_BLACK)
		end
	end
end

--����̩̹����ս����Ѫ��������
function DrawBox3(x1, y1, x2, y2, color)
	lib.DrawRect(x1, y1, x2, y1, color)
	lib.DrawRect(x1, y2, x2, y2, color)
	lib.DrawRect(x1, y1, x1, y2, color)
	lib.DrawRect(x2, y1, x2, y2, color)
	--�޾Ʋ����������������ķָ���
	--lib.DrawRect(x1, y1+(y2-y1)/2+1, x2, y1+(y2-y1)/2+1, color)
end

--��ʾ���ж�����ѡ���ս�������
function WarSelectTeam_Enhance()
	if JY.Restart == 1 then
		do return end
	end
	local T_Num=GetTeamNum();
	--�޾Ʋ������߶���3Ϊ��λ����
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

	--��ͨģʽ
	if true then
		for i = 1, 6 do
			WAR.Data["�Զ�ѡ���ս��" .. i] = -1
		end
	end

	--���õı���ͼ
	--û���Զ�ѡ���ս��ʱ����ʾ
	--�����´ﺣս�����ж�
	if WAR.Data["�Զ�ѡ���ս��1"] == -1 and not (WAR.ZDDH == 92 and GetS(87,31,33,5) == 1) then
		Clipped_BgImg((CC.ScreenW - width) / 2,(CC.ScreenH - height) / 2,(CC.ScreenW + width) / 2,(CC.ScreenH + height) / 2,1000)
		Clipped_BgImg((CC.ScreenW - (CC.DefaultFont+4)*4) / 2,(CC.ScreenH - height) / 2-(CC.DefaultFont+4)/2,(CC.ScreenW + (CC.DefaultFont+4)*4) / 2,(CC.ScreenH - height) / 2+(CC.DefaultFont+4)/2,1000)
	end
	for i=1,T_Num do
		local pid=JY.Base["����"..i];
		if pid <0 then
			break;
		end

	  --�������������´ﺣ
		if WAR.ZDDH == 92 and GetS(87,31,33,5) == 1 then
			WAR.Data["�Զ�ѡ���ս��1"] = 0;
			WAR.Data["�ҷ�X1"] = 33
			WAR.Data["�ҷ�Y1"] = 24
		end

		--ս���ɣ�����������ڶ����������س�ս
		if WAR.ZDDH == 253 and inteam(631) then
			WAR.Data["�ֶ�ѡ���ս��2"] = 631
		end

		--��������������ս
		if (WAR.ZDDH == 272 or WAR.ZDDH == 273) and JY.Base["����"] == 58 then
			WAR.Data["�Զ�ѡ���ս��2"] = 59
		end

		for i = 1, 6 do
			local id = WAR.Data["�Զ�ѡ���ս��" .. i]
			if id >= 0 then
				--�����������������ǻ�ȡ��ǿ�Ƴ�ս�Ķ���
				if id == JY.Base["����"] then
					WAR.Person[WAR.PersonNum]["������"] = 0
				else
					WAR.Person[WAR.PersonNum]["������"] = id
				end
				WAR.Person[WAR.PersonNum]["�ҷ�"] = true
				WAR.Person[WAR.PersonNum]["����X"] = WAR.Data["�ҷ�X" .. i]
				WAR.Person[WAR.PersonNum]["����Y"] = WAR.Data["�ҷ�Y" .. i]
				WAR.Person[WAR.PersonNum]["����"] = false
				WAR.Person[WAR.PersonNum]["�˷���"] = 2
				--�޾Ʋ���������ս����ʼ����
				--ս����
				if WAR.ZDDH == 259 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 1
				end
				--˫������ֹ
				if WAR.ZDDH == 273 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 1
				end
				--���������
				if WAR.ZDDH == 275 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--ս����
				if WAR.ZDDH == 75 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--�ɸ�
				if WAR.ZDDH == 278 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--������������
				if WAR.ZDDH == 279 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--��������
				if WAR.ZDDH == 293 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--��ڤ����
				if WAR.ZDDH == 295 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 0
				end
				--��������Ⱥ
				if WAR.ZDDH == 298 then
					WAR.Person[WAR.PersonNum]["�˷���"] = 1
				end
				WAR.PersonNum = WAR.PersonNum + 1
			end
		end

		if WAR.PersonNum > 0 and WAR.ZDDH ~= 235 then
			return
		end

		lib.PicLoadFile(string.format(CC.FightPicFile[1],JY.Person[pid]["ͷ�����"]),
		string.format(CC.FightPicFile[2],JY.Person[pid]["ͷ�����"]), 4+i);
		local n=0;
		local m=0;
		for j=1,5 do
			if JY.Person[pid]['���ж���֡��'..j]>0 then
				if j>1 then
					m=j;
					break;
				end
				n=n+JY.Person[pid]['���ж���֡��'..j]
			end
		end
		p[i]= {id=pid, name=JY.Person[pid]["����"];
		Pic=n*8+JY.Person[pid]['���ж���֡��'..m]*6, PicNum=JY.Person[pid]['���ж���֡��'..m], idx=0,
		x=x2+((i+3)%4)*pic_w, y=y2+math.modf((i+3)/4)*pic_h, x=x2+((i+2)%3)*pic_w, y=y2+math.modf((i+2)/3)*pic_h, picked=0,
		};
		--�޾Ʋ�����ǿ�Ƴ�ս�Ķ���
		for j = 1, 6 do
			if WAR.Data["�ֶ�ѡ���ս��" .. j] == p[i].id then
				p[i].picked = 1
				WAR.MCRS = WAR.MCRS + 1
			end
		end
	end
	--�������ж���3��
	WAR.MCRS = WAR.MCRS + 3
	--[[ս����
	if WAR.ZDDH == 253 then
		WAR.MCRS = WAR.MCRS + 3
	end

	--��ң���� ��ع��� ̫��ʫ�� ��Ĺ��ɼ �����ɾ�
	--�޶�1��
	if WAR.ZDDH == 281 or WAR.ZDDH == 283 or WAR.ZDDH == 284 or WAR.ZDDH == 285 or WAR.ZDDH == 286 then
		WAR.MCRS = WAR.MCRS + 5
	end

	--�������
	--�޶�2��
	if WAR.ZDDH == 280 then
		WAR.MCRS = WAR.MCRS + 4
	end]]

	p[0]={name="ȫ��ѡ��"};

	if T_Num>6 then
		p[0]={name="�Զ�ѡ��"}
	end

	p[T_Num+1]={name="��ʼս��"};
	local leader=-1;
	--�޾Ʋ�����ǿ�Ƴ�ս��Ԥ��leader
	for i=1,T_Num do
		if p[i].picked == 1 then
			leader = i
			break
		end
	end
	DrawBoxTitle(width,height,'��ս׼��',C_ORANGE);
	local select=1;
	local sid=lib.SaveSur(0,0,CC.ScreenW,CC.ScreenH);
	local function redraw(zdrs)
		lib.LoadSur(sid,0,0);
		DrawBox(x0,y1,x0+CC.DefaultFont*5+4*2,y1+CC.DefaultFont*(T_Num+2)+4*(T_Num+3),C_WHITE);
		for i=0,T_Num+1 do
			local str=p[i].name;
			--ѡ��ʱ��������ʾ
			--С��7�ˣ�����ǰ��ʾ�̱�ʾ��ѡ��
			--���ڵ���7�ˣ�����ǰ��ʾ����ʾ��Ҫȡ�����ɿ�ʼս��
			if i > 0 and i < T_Num+1 and p[i].picked > 0 then
				if zdrs < 7 then
					str="��"..str;
				else
					str="��"..str
				end
			--δѡ�е�ֻ��ʾ����
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
				--DrawString(p[i].x-CC.DefaultFont,p[i].y-CC.DefaultFont/2,"��ս",C_WHITE,CC.DefaultFont*2/3)
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
				if p[0].name=="ȫ��ѡ��" or p[0].name=="�Զ�ѡ��" then
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
					p[0].name="ȫ��ȡ��";
				elseif p[0].name=="ȫ��ȡ��" then
					for i=1,T_Num do
						if p[i].picked == 2 then
							p[i].picked=0;
							WAR.MCRS=WAR.MCRS-1
						end
					end
					leader=-1;
					--�޾Ʋ�����ǿ�Ƴ�ս��Ԥ��leader
					for i=1,T_Num do
						if p[i].picked == 1 then
							leader = i
							break
						end
					end
					p[0].name="ȫ��ѡ��"

					if T_Num>6 then
						p[0].name="�Զ�ѡ��"
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
							WAR.Person[WAR.PersonNum]["������"]=JY.Base["����" ..px[i]]
							WAR.Person[WAR.PersonNum]["�ҷ�"]=true
							WAR.Person[WAR.PersonNum]["����X"]=WAR.Data["�ҷ�X"..i]
							WAR.Person[WAR.PersonNum]["����Y"]=WAR.Data["�ҷ�Y"..i]
							WAR.Person[WAR.PersonNum]["����"]=false
							WAR.Person[WAR.PersonNum]["�˷���"]=2
							--�޾Ʋ���������ս����ʼ����
							--ս����
							if WAR.ZDDH == 259 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 1
							end
							--˫������ֹ
							if WAR.ZDDH == 273 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 1
							end
							--���������
							if WAR.ZDDH == 275 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--ս����
							if WAR.ZDDH == 75 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--�ɸ�
							if WAR.ZDDH == 278 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--������������
							if WAR.ZDDH == 279 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--��������
							if WAR.ZDDH == 293 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--��ڤ����
							if WAR.ZDDH == 295 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 0
							end
							--��������Ⱥ
							if WAR.ZDDH == 298 then
								WAR.Person[WAR.PersonNum]["�˷���"] = 1
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
						p[0].name="ȫ��ѡ��"

						if T_Num>6 then
							p[0].name="�Զ�ѡ��"
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
							p[0].name="ȫ��ȡ��";
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

--������Ӱ
function kuihuameiying()
	local x, y
	for i = 0, WAR.PersonNum - 1 do
		if WAR.Person[i]["������"] == 0 then
			x, y = WAR.Person[i]["����X"], WAR.Person[i]["����Y"]
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
		CurIDTXDH(WAR.CurID, 120, 1, "������Ӱ", C_GOLD)
		lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, -1)
		lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, -1)
		WarDrawMap(0)
		WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"] = telx, tely
		WarDrawMap(0)
		CurIDTXDH(WAR.CurID, 120, 1, "������Ӱ", C_GOLD)
		lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 5, WAR.Person[WAR.CurID]["��ͼ"])
		lib.SetWarMap(WAR.Person[WAR.CurID]["����X"], WAR.Person[WAR.CurID]["����Y"], 2, WAR.CurID)
		WarDrawMap(0)
		return true
	else
		return false
	end
end

function NeiLiDamage(pid, dmg)
	if JY.Person[pid]["����"] == 0 then
		dmg = dmg * 2
	end
	local neili = JY.Person[pid]["����"]
	if neili >= dmg then
		JY.Person[pid]["����"] = JY.Person[pid]["����"] - dmg
	else
		WAR.Person[WAR.CurID]["��������"] = AddPersonAttrib(pid, "����", - 2 * dmg + 2 * JY.Person[pid]["����"]);
		JY.Person[pid]["����"] = 0
		Cls();
		War_Show_Count(WAR.CurID, "�;��ƿ���Ѫ��ʧ");
	end
end

--��а��ʽ
function BiXieZhaoShi(id,MiaofaWX)
	WAR.BXZS = 0
	if not WAR.BXLQ[id] then
		WAR.BXLQ[id] = {0,0,0,0,0,0}
	end
	local zs={
	{name="ָ���а",Usable=true,m1=1,m2=1,a1=1,a2=3+MiaofaWX,a3=3+MiaofaWX},
	{name="���ഩ��",Usable=true,m1=3,m2=1,a1=10,a2=8+MiaofaWX,a3=7+MiaofaWX,a4=6+MiaofaWX},
	{name="��������",Usable=true,m1=0,m2=0,a1=5,a2=6+MiaofaWX,a3=3+MiaofaWX},
	{name="��ظ��Ŀ",Usable=true,m1=0,m2=5,a1=2,a2=4+MiaofaWX},
	{name="ɨ��Ⱥħ",Usable=true,m1=3,m2=1,a1=11,a2=6+MiaofaWX},
	{name="��������",Usable=true,m1=0,m2=6,a1=3,a2=3+MiaofaWX,a3=3+MiaofaWX},
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
		DrawString(500, 520, "��ʽ������"..CC.KFMove[48][choice][2], C_WHITE, size)
		if WAR.BXCD[choice] == 0 or match_ID(id, 36) then
			DrawString(500, 570, "��ȴʱ�䣺��", C_WHITE, size)
		else
			DrawString(500, 570, "��ȴʱ�䣺"..WAR.BXCD[choice].."�غ�", C_WHITE, size)
		end
		if choice > 2 and not PersonKF(id,105) then
			DrawString(500, 620, "ϰ�ÿ����񹦺󷽿�ʹ��", C_WHITE, size)
		elseif WAR.BXLQ[id][choice] > 0 then
			DrawString(500, 620, "��ȴ�У�"..WAR.BXLQ[id][choice].."�غϺ���ٴ�ʹ��", C_WHITE, size)
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