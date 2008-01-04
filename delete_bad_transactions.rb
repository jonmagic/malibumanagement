
def report(txt)
  begin
    puts(("  "*CoresExtensions::StepLevel[0]) + ">" + txt)
    ActionController::Base.logger.info("  "*CoresExtensions::StepLevel[0] + ">" + txt)
  rescue => e
    puts e
  end
end

# [client_id, transaction_id]
zone1 = [[20000999, 2297564], [20001681, 2297565], [20001837, 2297566], [20003675, 2297567], [20004718, 2297568], [20005442, 2297569], [20007134, 2297570], [20007453, 2297571], [20008919, 2297572], [20008920, 2297573], [20009327, 2297574], [20009670, 2297575], [20009837, 2297576], [20010256, 2297577], [20011904, 2297578], [20012691, 2297579], [20014941, 2297580], [20015603, 2297581], [20015663, 2297582], [20015733, 2297583], [20016090, 2297584], [20016794, 2297585], [20016906, 2297586], [20016963, 2297587], [20017647, 2297588], [20017660, 2297589], [20017735, 2297590], [20017740, 2297591], [21000054, 2297592], [21000337, 2297593], [21000577, 2297594], [21000617, 2297595], [21000670, 2297596], [21000931, 2297597], [21001180, 2297598], [21001668, 2297599], [21002476, 2297600], [21002627, 2297601], [21002700, 2297602], [21002931, 2297603], [21003002, 2297604], [21003083, 2297605], [21003167, 2297606], [21003367, 2297607], [21003652, 2297608], [21003706, 2297609], [21003925, 2297610], [21004008, 2297611], [21004206, 2297612], [21004410, 2297613], [21004552, 2297614], [21004621, 2297615], [21004702, 2297616], [21004835, 2297617], [21005070, 2297618], [21005509, 2297619], [21005991, 2297620], [21006071, 2297621], [21006504, 2297622], [21006783, 2297623], [21006833, 2297624], [21007491, 2297625], [21007962, 2297626], [21009176, 2297627], [21009266, 2297628], [21009473, 2297629], [21009579, 2297630], [21009718, 2297631], [21009837, 2297632], [21010342, 2297633], [21010552, 2297634], [21010562, 2297635], [21010583, 2297636], [21010585, 2297637], [21010788, 2297638], [21011104, 2297639], [21011301, 2297640], [21011448, 2297641], [21011476, 2297642], [21011549, 2297643], [21011659, 2297644], [21011661, 2297645], [21011751, 2297646], [21011844, 2297647], [21011912, 2297648], [21011990, 2297649], [21012152, 2297650], [21012161, 2297651], [21012173, 2297652], [21012177, 2297653], [21012211, 2297654], [21012236, 2297655], [21012237, 2297656], [21012242, 2297657], [21012298, 2297658], [22001051, 2297659], [22001230, 2297660], [22001895, 2297661], [22002757, 2297662], [22003749, 2297663], [22005035, 2297664], [22005880, 2297665], [22006562, 2297666], [22007604, 2297667], [22009044, 2297668], [22009315, 2297669], [22009506, 2297670], [22010925, 2297671], [22011104, 2297672], [22011210, 2297673], [22011648, 2297674], [22011981, 2297675], [22012537, 2297676], [22012555, 2297677], [23000167, 2297678], [23009136, 2297679], [23009353, 2297680], [23010339, 2297681], [23010692, 2297682], [23011707, 2297683], [23012931, 2297684], [23014069, 2297685], [23014587, 2297686], [23014878, 2297687], [23014943, 2297688], [23015044, 2297689], [23015244, 2297690], [23015722, 2297691], [23015740, 2297692], [23015789, 2297693], [24000450, 2297694], [24001277, 2297695], [24001676, 2297696], [24003069, 2297697], [24013268, 2297698], [24013422, 2297699], [24013716, 2297700], [24014295, 2297701], [24014551, 2297702], [24014779, 2297703], [24015243, 2297704], [24015814, 2297705], [24015819, 2297706], [24015833, 2297707], [25000222, 2297708], [25005363, 2297709], [25006700, 2297710], [25007627, 2297711], [25012556, 2297712], [25013132, 2297713], [25013288, 2297714], [25013652, 2297715], [25013767, 2297716], [25015361, 2297717], [25015436, 2297718], [25015630, 2297719], [25016318, 2297720], [25016383, 2297721], [25016940, 2297722], [25017141, 2297723], [25017720, 2297724], [25017753, 2297725], [25017772, 2297726], [25017837, 2297727], [25017838, 2297728], [25017887, 2297729], [25018571, 2297730], [25018572, 2297731], [25018701, 2297732], [25018702, 2297733], [25018749, 2297734], [25018784, 2297735], [25018804, 2297736], [25018812, 2297737], [25018823, 2297738], [25018825, 2297739], [26000565, 2297740], [26001281, 2297741], [26001329, 2297742], [26001337, 2297743], [26001351, 2297744], [26001381, 2297745], [26001382, 2297746], [27000005, 2297747], [27000008, 2297748], [27000018, 2297749], [27000021, 2297750], [27000022, 2297751], [27000026, 2297752], [27000034, 2297753], [27000035, 2297754], [27000044, 2297755], [27000047, 2297756], [27000051, 2297757], [27000053, 2297758], [27000058, 2297759], [27000059, 2297760], [27000061, 2297761], [27000067, 2297762], [27000078, 2297763], [27000081, 2297764], [27000098, 2297765], [27000100, 2297766], [27000101, 2297767], [27000102, 2297768], [27000112, 2297769], [27000125, 2297770], [27000130, 2297771], [27000132, 2297772], [27000136, 2297773], [27000138, 2297774], [27000139, 2297775], [27000145, 2297776], [27000148, 2297777], [27000153, 2297778], [27000160, 2297779], [27000166, 2297780], [27000170, 2297781], [27000171, 2297782], [27000173, 2297783], [27000184, 2297784]]
zone2 = [[1000380, 1724742], [1001583, 1724743], [1001702, 1724744], [1003381, 1724745], [1005464, 1724746], [1006648, 1724747], [1006848, 1724748], [1007537, 1724749], [1007594, 1724750], [1008052, 1724751], [1008053, 1724752], [1008388, 1724753], [1008430, 1724754], [1008519, 1724755], [1008728, 1724756], [1008935, 1724757], [1008947, 1724758], [1009141, 1724759], [1009143, 1724760], [1009163, 1724761], [1009169, 1724762], [1009177, 1724763], [2000301, 1724764], [2000367, 1724765], [2000741, 1724766], [2000997, 1724767], [2001126, 1724768], [2001391, 1724769], [2001629, 1724770], [2001635, 1724771], [2001843, 1724772], [2001844, 1724773], [2001845, 1724774], [2001846, 1724775], [2001854, 1724776], [2001858, 1724777], [2001859, 1724778], [3000026, 1724779], [3000589, 1724780], [3001564, 1724781], [3002004, 1724782], [3004212, 1724783], [3005235, 1724784], [3005721, 1724785], [3005732, 1724786], [3005940, 1724787], [3005946, 1724788], [3006445, 1724789], [3006554, 1724790], [3006979, 1724791], [3007091, 1724792], [3007551, 1724793], [3007566, 1724794], [3007580, 1724795], [3007778, 1724796], [3008144, 1724797], [4000100, 1724798], [4000104, 1724799], [4000500, 1724800], [4000658, 1724801], [4000881, 1724802], [4001075, 1724803], [4001143, 1724804], [4001273, 1724805], [4001429, 1724806], [4001636, 1724807], [4001916, 1724808], [4002083, 1724809], [4002678, 1724810], [4005595, 1724811], [4005776, 1724812], [4006442, 1724813], [4006816, 1724814], [4007201, 1724815], [4007456, 1724816], [4007915, 1724817], [4007960, 1724818], [4008012, 1724819], [4008186, 1724820], [4008195, 1724821], [4008265, 1724822], [4008679, 1724823], [4008701, 1724824], [4008796, 1724825], [4008837, 1724826], [4009102, 1724827], [4009193, 1724828], [4009296, 1724829], [4009513, 1724830], [4009515, 1724831], [4009541, 1724832], [4009542, 1724833], [4009570, 1724834], [5000153, 1724835], [5000210, 1724836], [5000292, 1724837], [5000301, 1724838], [5000791, 1724839], [5001024, 1724840], [5001601, 1724841], [5002057, 1724842], [5002085, 1724843], [5002217, 1724844], [5002405, 1724845], [5002833, 1724846], [5003452, 1724847], [5003631, 1724848], [5003675, 1724849], [5003925, 1724850], [5004514, 1724851], [5004679, 1724852], [5004700, 1724853], [5004902, 1724854], [5005125, 1724855], [5005469, 1724856], [5005644, 1724857], [5005922, 1724858], [5006138, 1724859], [5006144, 1724860], [5006146, 1724861], [5006151, 1724862], [5006157, 1724863], [5006158, 1724864], [5006162, 1724865], [5006163, 1724866], [5006172, 1724867], [5006175, 1724868], [5006178, 1724869], [6000008, 1724870], [6000076, 1724871], [6000275, 1724872], [6000376, 1724873], [6000418, 1724874], [6000596, 1724875], [6001074, 1724876], [7000014, 1724877], [7000173, 1724878], [7000407, 1724879], [7000790, 1724880], [7001067, 1724881], [7002005, 1724882], [7002016, 1724883], [7002019, 1724884], [7002091, 1724885], [7002803, 1724886], [7003612, 1724887], [7003833, 1724888], [7004081, 1724889], [7004363, 1724890], [7004383, 1724891], [7004437, 1724892], [7004524, 1724893], [7004824, 1724894], [7004825, 1724895], [7004828, 1724896], [7004830, 1724897], [7004835, 1724898], [7004842, 1724899], [8000093, 1724900], [8000443, 1724901], [8000728, 1724902], [8001189, 1724903], [8001319, 1724904], [8001578, 1724905], [8001746, 1724906], [8001843, 1724907], [8002613, 1724908], [8002660, 1724909], [8002695, 1724910], [8002698, 1724911], [8002699, 1724912], [8002715, 1724913], [8002724, 1724914], [8002736, 1724915], [8002737, 1724916], [8002738, 1724917], [8002739, 1724918], [8002742, 1724919], [8002752, 1724920], [8002770, 1724921], [8002774, 1724922], [8002794, 1724923], [8002811, 1724924], [8002814, 1724925], [9000004, 1724926], [9000014, 1724927], [9000100, 1724928], [9000214, 1724929], [9000498, 1724930], [9000551, 1724931], [9000616, 1724932], [9000636, 1724933], [9000669, 1724934], [9000694, 1724935], [9000744, 1724936], [9000989, 1724937], [9001054, 1724938], [9001077, 1724939], [9001125, 1724940], [9001127, 1724941], [9001130, 1724942], [9001135, 1724943], [9001136, 1724944], [9001151, 1724945], [9001156, 1724946], [9001161, 1724947], [9001166, 1724948], [9001176, 1724949], [9001180, 1724950], [9001181, 1724951], [9001186, 1724952], [9001187, 1724953], [9001200, 1724954], [9001227, 1724955], [9001232, 1724956], [9001234, 1724957], [9001241, 1724958], [9001259, 1724959], [9001266, 1724960], [9001278, 1724961], [9001286, 1724962], [9001289, 1724963], [9001290, 1724964], [9001291, 1724965], [9001304, 1724966]]

data = nil
if ZONE[:Division] == 1
  data = zone2
elsif ZONE[:Division] == 2
  data = zone1
end

data.each do |a|
  client_id = a[0]
  transaction_id = a[1]
  step("Destroying all transactions") do
    Helios::Transact.slaves.each_key do |slave_name|
      step("Destroying #{transaction_id} for client #{client_id}") do
        report Helios::Transact.update_on_slave(slave_name, transaction_id, :CType => 1, :client_no => client_id)
      end
    end
  end
end
