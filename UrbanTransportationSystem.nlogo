extensions [array table] ;; 使用数组和哈希表拓展

;; 定义海龟种类 其中，mapping-<xx>为视图，用于连接顶点
breed [citizens          citizen] ;; 居民
breed [mapping-citizens  mapping-citizen] ;; mapping-citizens为视图上的居民（可为私家车）。
breed [buses             bus]
breed [mapping-buses     mapping-bus]
breed [taxies            taxi]
breed [mapping-taxies    mapping-taxi]
breed [vertices          vertex]               ;; Graph Algorithm 用于查找最短路径的迪杰斯特拉算法：顶点集合
undirected-link-breed [edges       edge]       ;; Graph Algorithm 用于查找最短路径的迪杰斯特拉算法：边集
undirected-link-breed [map-links   map-link]   ;; link between controller and entity ;; 无向链，link model agent with view agent
undirected-link-breed [bus-links   bus-link]   ;; link between bus(vehicle) and passenger
undirected-link-breed [taxi-links  taxi-link]  ;; link between taxi and passenger

undirected-link-breed [rideSharingLinks  rideSharingLink]  ;; 合乘乘客和司机的无向链

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables 全局变量
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals[
  ;;  configuration
  district-width ;; 区域宽度
  district-length ;; 区域长度
;  initial-people-num 由滑块控制
  company-capacity ;; 一个公司的人数
  residence-capacity ;; 一个住所的人数
  bus-capacity
  ;;  interaction
  mouse-was-down? ;; 鼠标点击事件
  ;;  time control
  traffic-light-cycle
  traffic-light-count
  ;;  transportation
  person-speed             ;;  person
  car-speed                ;;  car
  bus-speed                ;;  bus
  acceleration
  deceleration
  event-duration           ;;  person: work and rest
  bus-duration             ;;  bus: wait 公交车每站经停时间
  taxi-duration            ;;  taxi: wait 出租车经停时间
  buffer-distance          ;;  safe distance to the car ahead ;; 与前车的默认安全距离
  ;;  game parameter
  money ;; 所有人的金钱总量？
  ;;  patch-set patch主体集合
  roads
  intersections
  idle-estates ;; 闲置地产（就是除了land（棕色）之外没人住的地方）
  residence-district ;; 住所区域
  company-district ;; 公司区域
  residences
  companies
  ;;  patch
  global-origin-station ;; 源点O
  global-terminal-station ;; 终端点D
  ;;  Analysis
  average-taxi-carring-rate-list
  average-commuting-time-list
  average-bus-carring-number-list
]

citizens-own[
  ;;  basic
  residence
  company

  ;;  game
  earning-power ;; 赚钱能力？
  ;;  transportation
  trip-mode                ;;  		1 take car 2 take bus 3 take taxi 4 taxi 5 bus 6 顺风车（乘客）
  path ;;一个路径list，由寻路方法获得
  max-speed
  ;; round
  speed
  advance-distance
  still? ;;是否静止，布尔型变量
  time ;;
  ;; trip
  last-commuting-time ;; 记录上一次tick的通勤时间
  commuting-counter ;; 居民走了多少时间，每次tick时加1

  ;; 确定出行方式相关的工作时间
  workTime

  ;; 出行行为选择的变量
  travelMethod

  ;; 用于确定出行方式的效益模型
  income       ;; 实际收入值
  has-car?     ;; 布尔型变量，是否有车 true有，false无， （用于编程）
  hasCar       ;; 是否有车， 1有，0无
  education    ;; 1 高中及以下， 2 大专，3 本科，4 硕士及以上
  age          ;; 实际年龄值
  occupation   ;; 1 学生，2 工人， 3 公务员，4 员工， 5 自由职业者， 6 退休者
  sex          ;; 0 男， 1女

  ;; 用于顺风车（司机）
  isOrdered? ;; 当前司机是否被预定
  occupiedNum ;; 当前司机匹配乘客人数
  pathList ;; 路径列表，存放司机到第一、第二个乘客的路径

  orderedNum ;; 记录顺风车的预定数，最多一次预定两个

  lastStayAt ;; 记录上次呆过的地方, 0 表示家，1表示公司
  lastTripMode ;; 记录上次的出行方式

]

;; 出租车
taxies-own [
  ;;  transportation
  trip-mode                ;;  4: taxi
  path
  max-speed
  ;;  round
  is-ordered? ;; 是否被预定
  is-occupied? ;; 是被乘客占用（乘客上车）
  speed
  advance-distance
  still? ;; 是否静止，布尔型变量
  time
]

;; 公交车
buses-own [
  ;;  basic
  origin-station           ;;  vertex
  terminal-station         ;;  vertex
  ;;  transportation
  trip-mode                ;;  5: bus
  path
  max-speed
  ;;  round
  num-of-passengers ;; 车上乘客数
  speed
  advance-distance
  still?
  time ;;
]

patches-own[
  land-type                ;; 字符串变量，  land, road, bus-stop, residence, company, idle-estate
  intersection?            ;; 是否为交叉口
  num                      ;;  land-type = "residence" 时，num为该住所人数；为 "company"时，land-type为该公司容量,都不是时为0
]

vertices-own [
  weight ;; 权重
  predecessor ;;该顶点前驱
]

edges-own [
  bus-route? ;; 是否为公交线路
  cost ;; 代价
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-config
  setup-globals
  setup-patches
  setup-estates
  setup-map
  setup-citizens
  setupTaxi
  reset-ticks
end

;; 配置设置
to setup-config
  set district-width       7
  set district-length      7
;  set initial-people-num   80 ;; 设置滑块的值为80
  set company-capacity     5 ;; 一个公司的人数
  set residence-capacity   1 ;; 住所人数
  set bus-capacity         4 ;; 公交人数
  set mouse-was-down?      false
  set traffic-light-cycle  1
  set traffic-light-count  traffic-light-cycle ;; traffic-light-count为倒计时，当为零时改变相位，初始时设置为周期
end

to setup-globals
  ;; speed：相对于砖块
  set person-speed         0.085
  set car-speed            0.4385
  set bus-speed            0.2424028
  set acceleration         0.25
  set deceleration         0.5
  set event-duration       720
  set bus-duration         2 ;;
  set taxi-duration        2 ;;
  set buffer-distance      1.0 ;; 缓冲距离为一个砖块
  set money                0
end

to setup-patches
  ask patches [
    set intersection? false
  ]
  ;;  roads
  ask patches with [
    pxcor mod (district-width + 1) = 0 or pycor mod (district-length + 1) = 0 ;; 一个区域的长、宽外设置为road，占1个patch
  ][
    set land-type "road"
    set pcolor gray + 4 ;; 道路颜色为接近白色
  ]
  set roads patches with [land-type = "road"] ;; 将land-type为road的patches设置为road种类
  ;;  intersections
  ask patches with [
    pxcor mod (district-width + 1) = 0 and pycor mod (district-length + 1) = 0
  ][
    set intersection? true ;; 设置交叉口属性
  ]
  set intersections patches with [intersection? = true]
  ;;  traffic lights
  ask intersections [
    ;; 为每个intersection的相邻patches设置名称
    let right-patch patch-at  1  0
    let left-patch  patch-at -1  0
    let up-patch    patch-at  0  1
    let down-patch  patch-at  0 -1
    ;; 若存在则设置颜色
    if right-patch != nobody [ ask right-patch [set pcolor 69] ]
    if left-patch  != nobody [ ask left-patch  [set pcolor 69] ]
    if up-patch    != nobody [ ask up-patch    [set pcolor 19  ] ]
    if down-patch  != nobody [ ask down-patch  [set pcolor 19  ] ]
  ]
  ;;  land
  ask patches with [land-type != "road"][
    set land-type "land"
    set pcolor green ;; 公共用地用绿色
  ]
  ;;  idle estate
  ask patches with [
    any? neighbors with [land-type = "road"] and land-type = "land"
  ][
    set land-type "idle-estate"
    set pcolor grey ;; 未开发用地用灰色
  ]
  set idle-estates patch-set patches with [land-type = "idle-estate"] ;; patch-set 返回包含所有输入瓦片的主体集合
  ;;  residence-district 居住区域（注意不是住所）set
  set residence-district patch-set patches with [
    ((pxcor > max-pxcor / 2) or (pxcor < (- max-pxcor / 2)) or        ;;
    (pycor > max-pycor / 2) or (pycor < (- max-pycor / 2))) and
    (land-type = "idle-estate")
  ]
  ;;  company-district
  set company-district patch-set patches with [
    ((pxcor < max-pxcor / 2) and (pxcor > (- max-pxcor / 2)) and
    (pycor < max-pycor / 2) and (pycor > (- max-pycor / 2))) and
    ((land-type = "idle-estate"))
  ]
end

to setup-estates
  ;; 向下取整，得到住所和公司的数目
  let residence-num ceiling(initial-people-num / residence-capacity)
  let company-num   ceiling(initial-people-num / company-capacity  )
  ;;  residences
  ask n-of residence-num residence-district[
    set land-type "residence" ;; 随机选择住所区域的patch变为住所
  ]
  set residences patch-set patches with [land-type = "residence"] ;; 设置patch-set
  ask residences [
    set pcolor yellow
    set num 0 ;; num是一个标记，0代表residence，1代表company
  ]
  ;;  companies
  ;; 注意：companies的数据类型为patch-set,而不是vertices!
  ask n-of company-num company-district[
    set land-type "company"
  ]
  set companies patch-set patches with [land-type = "company"]
  ask companies [
    set pcolor red  ;; 通常用红色表示商业用地！！
    set num 0
  ]
end

;; 由setup-map、setup-citizen、add-citizen调用，生成边
to setup-graph
  let isTerminal? ([land-type] of patch-here = "residence" or [land-type] of patch-here = "company") ;;判断是否为终点 patch-here返回海龟下方的瓦片
  create-edges-with vertices-on neighbors4 with [land-type = "road"][ ;; neighbors4返回由4个相邻瓦片组成的主体集合
    set shape "dotted"
    set bus-route? false
    ifelse (isTerminal?)[
      set cost 20
    ][
      set cost 10
    ]
  ]
end

;;创建patch-set为roads、residences和companies的图（顶点和边）
to setup-map
  ;;  initialize vertices
  ask roads [                       ;; roads为一个patch-set型变量，在setup-patch函数中已初始化
    sprout-vertices 1 [hide-turtle] ;; sprout-<breeds> number [ commands ] 在当前瓦片上创建number个新海龟。新海龟的方向是随机整数，颜色从14个主色中随机产生。海龟立即运行commands，如果要给新海龟不同的颜色、方向等就比较有用。（新海龟是一次全部产生出来，然后以随机顺序每次运行1个）如果使用sprout-<breeds>形式，则新海龟属于给定的种类。
  ]                                 ;; hide-turtle等价于设置海龟变量的hidden? 为true
  ask residences [
    sprout-vertices 1 [hide-turtle]
  ]
  ask companies [
    sprout-vertices 1 [hide-turtle]
  ]
  ;;  initialize edges
  ask vertices [
    setup-graph ;; 生成边
  ]
end
;;给setup-citizens调用，在住所生成居民，调用者为当前新生成的居民
to setup-citizen
  ;;  set residence
  ask patch-here [ set num num + 1 ] ;; 当前patch的num属性加1（num表示该住所的居民数）
  ;;  set company
  let my-company one-of companies with [num < company-capacity] ;; 随机选择一个公司容量不满的公司作为该居民的公司
  if (my-company = nobody)[ ;; 若公司容量都满了
    let new-company one-of company-district with [land-type = "idle-estate"] ;; 在闲置地产找一块空地
    ask new-company [
      set land-type "company"
      set pcolor blue
      set num 0
      sprout-vertices 1 [ ;;生成顶点
        setup-graph ;; 生成边
        hide-turtle
      ]
    ]
    set companies (patch-set companies new-company) ;;重新设置compaines这个patch-set为compaines+new-company
    set my-company new-company
  ]
  ask my-company [ set num num + 1 ]


  ;;  set basic properties
  ;; residence和company都是vertex类型变量，而不是patch变量！
  set residence         one-of vertices-on patch-here
  set company           one-of vertices-on my-company
  set earning-power     5 ;;

  ;; 确定出行效益相关参数

  ;; 设置收入
  set income random-normal 7086 14000
  if income < 0 [
    set income 2200
  ]

  ;;  set has-car? 设定拥车率：设置为月收入高于10000元以上，有50%拥车；月收入低于10000元以下，有20%拥车
  ifelse income > 10000 [
    ifelse random 100 < 50 [
      set has-car? true
      set hasCar 1         ;; 与出行方式计算有关
      set color    magenta ;; 有车的人颜色为洋红色
    ][
      set has-car? false
      set hasCar 0
      set color    cyan ;; 无车的人颜色为青色
    ]
  ][
    ifelse random 100 < 20 [
      set has-car? true
      set hasCar 1
      set color    magenta ;; 有车的人颜色为洋红色
    ][
      set has-car? false
      set hasCar 0
      set color    cyan ;; 无车的人颜色为青色
    ]
  ]

  ;; 设置学历
  let eduProperty random 100
  if eduProperty <= 62.1197776 [
    set education 1
  ]
  if eduProperty > 62.1197776 and eduProperty <= 76.0750426 [
    set education 2
  ]
  if eduProperty > 76.0750426 and eduProperty <= 95.0225428 [
    set education 3
  ]
  if eduProperty > 95.0225428 and eduProperty <= 100 [
    set education 4
  ]

  ;; 设置年龄age
  set age random-normal 35.7 19.43579173
  if age < 0 [
    set age 1
  ]

  ;; 设置职业
  set occupation random 6 + 1

  ;; 设置性别
  set sex random 2



  ;; 设置工作时间(h为单位)
  set workTime random-normal 8 2

  ;; 设置顺风车（司机）相关
  set isOrdered?  false
  set occupiedNum 0
  set pathList    []
  set orderedNum  0


  ;;  set transportation properties
  set-max-speed           person-speed

  ;;  set other properties
  set speed               0
  set advance-distance    0 ;; 距离他人为0
  set still?              false ;; 开始行走
  set time                0 ;; 设置停止时间为2
  set last-commuting-time nobody ;; 控制event-duration
  set commuting-counter   0 ;; 通勤计次，每一个ticks加1

  ;;  set trip-mode 居民出行行为选择
  set-trip-mode

  ;; 若选择乘出租车或顺风车（乘客）出行，等待一段时间匹配出租车或顺风车
  if (trip-mode = 3 or trip-mode = 6)[
        halt 2
  ]

  ;; 顺风车（司机）和顺风车（乘客）初始化上次呆过的地方为家

  set lastStayAt 0

  ;; 初始化上次的出行方式
  set lastTripMode 0

  ;;  set path
  set path find-path residence company trip-mode ;; find-path是一个函数，输入三个参数：起点，终点，出行方式, 返回一个list是结点组成的路径

  ;;  hatch mapping person
  face first path ;; 设置居民朝向为第一个结点
  let controller         self ;; 将self（也就是居民）赋值给controller变量,controller也就是人
  let controller-heading heading
  ;;hide-turtle            ;; debug 隐藏当前居民controller，只显示mapping-citizen

  hatch-mapping-citizens 1 [ ;; 本residence孵化一个mapping-citizen，并：
    set shape          "person business"
    set color          color ;; 将residence的颜色设置为mapping-citizen的颜色
    set heading        heading
    ;; 为了区分citizen和mapping-citizen，所以设置一个位移
    rt 90 ;; 右转90度
    fd 0.25 ;; 前进0.25
    lt 90 ;; 左转90度
    create-map-link-with controller [tie] ;; 当前mapping-citizen与citizen连接（map-link是连接mapping-citizen和controller的无向链,tie为捆绑在一起，影响运动和方向
    show-turtle ;; 若没有这个语句，则视图上就没有turtle了
  ]

  ;;  set shape
  ;;set-moving-shape
end

to setup-citizens
  set-default-shape citizens "person business"
  ask residences [
    sprout-citizens residence-capacity [
      setup-citizen ;;在住所生成居民
    ]
  ]
end

to setupTaxi
  let i 0
  while [i < 20] [
    add-taxi
    set i i + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transportation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  fundamental movement
to advance [len]
  ifelse (advance-distance > len) [ ;; 若前面主体的距离大于len
    fd len
    set advance-distance advance-distance - len ;; 重新计算前车距离
  ][ ;; 若小于len
    fd advance-distance ;; 前进这个数
    set advance-distance 0 ;; 设前车距离为0
  ]
end

;; 停duartion的时间 若duration为0，则是设置其still为true和speed为0 time就是需要停止的变量
to halt [duration]
  set time   duration
  set still? true
  set speed  0
end

;;  taxi-related 返回一个taxi主体，若没找到就返回null, 由citizen调用
to-report find-taxi
  let this             self
  let available-taxies ((taxies with [is-ordered? = false and is-occupied? = false]) in-radius 50) ;; 在taxi-detect-distance范围内找一个没被预定且没被占用的taxi
  ifelse count available-taxies > 0 [
    report min-one-of available-taxies [distance this] ;; 返回距离最近的出租车
  ][
    report nobody
  ]
end

;;返回一个顺风车司机主体，若没找到就返回null, 由citizen调用
to-report findRideDriver
  let this self
  ;; 合乘匹配
  ;; todo: 按照设计算法实现
  let availableDrivers ((citizens with [trip-mode = 7 and time <= 0 and orderedNum < 2 and occupiedNum < 2 and not (orderedNum = 1 and occupiedNum = 1)]) in-radius 50) ;; time<=0:当顺风车司机在路上时
  ifelse count availableDrivers > 0 [
    ;;show "find it"
    report min-one-of availableDrivers [distance this] ;; 返回距离最近的顺风车司机
  ][
    report nobody
  ]
end

;;  bus-related 公交车让乘客下车，由公交车主体调用
to passengers-off
  let this  self ;; this为bus主体
  ifelse length path > 0 [ ;; 若bus主体没到终点
    let next-station first path ;; 设置下一个站点为下一个路径结点
    if (any? bus-link-neighbors)[ ;; 若当前公交车上有人
      ask bus-link-neighbors [
        ;; 更新公交车上居民的path
        if (distance first path < 0.0001)[
          set path but-first path
        ]
        ;; 若更新后的path的第一个路径结点不是公交车的下一站
        if (first path != next-station)[
          ask link-with this [
            die ;; 乘客解除与当前公交车的绑定关系（即下车）
          ]
          set still? false ;; 乘客恢复自由活动
          ask one-of map-link-neighbors [ set size 1.0 ]  ;; 视图上的乘客恢复可见性
          passengers-on-off  ;; transfer to another bus 寻找下一个公车
        ]
      ]
    ]
    ;; 当前公车上的乘客重新设定
    set num-of-passengers count bus-link-neighbors
  ][ ;; 若bus主体到了终点
    if (any? bus-link-neighbors)[ ;; 若有乘客
      ;; 让所有乘客下车
      ask bus-link-neighbors [
        ask link-with this [
          die
        ]
        set still? false
        ask one-of map-link-neighbors [ set size 1.0 ]
      ]
      set num-of-passengers  0  ;; all passengers off
    ]
  ]
end

;; 在车上的乘客下车动作，由各个主体调用！
;; todo:顺风车下车逻辑（取消绑定逻辑）
to passengers-on-off
  ;; bus
  if trip-mode = 2 [ ;; 若居民出行方式为take bus
    if (length path > 0 and distance first path > 1.0001)[ ;; 当居民距离第一个路径结点距离大于一个patch时，居民静止
      halt 0
    ]
  ]
  if trip-mode = 5 [ ;; 主体为bus
    halt bus-duration ;; 公交车经停等待
    passengers-off ;; 乘客在该站下车
  ]

  ;; 主体为出租车（乘客）
  if trip-mode = 3 [ ;; 主体为居民，出行方式为出租车（乘客）
    if (patch-here = [patch-here] of company or patch-here = [patch-here] of residence) [ ;; 若居民已到达公司或住所（即已到达终点）


      set trip-mode 2 ;; 设置出行方式为take bus
      ;; 下出租车, 解除绑定后出租车可自由移动了
      ask one-of taxi-link-neighbors [
        if (is-occupied?)[
          ask my-taxi-links [die]
          set is-occupied? false
          set still?       false
          set-path
          face first path
        ]
      ]
    ]
  ]

  ;; 主体为顺风车（乘客）
  if trip-mode = 6 [
    ;; 保存当前乘客
    let this self;

    if (patch-here = [patch-here] of company or patch-here = [patch-here] of residence) [ ;; 若当前乘客已到达公司或住所（即已到达终点）
      ;; debug
      show "passenger arrived"

      ;; 对于顺风车乘客，记录上次呆的地方





      set trip-mode 2 ;; 设置出行方式为take bus
                      ;; 当前居民下顺风车





      ;; 对于该乘客的顺风车司机
      let driver one-of rideSharingLink-neighbors
      ask driver [

        if (occupiedNum <= 2)[

          ;; 若当前顺风车乘客为2人，即第一个乘客到达目的地时,让第二个乘客可移动，前往第二个乘客的目的地
          ifelse occupiedNum = 2 [

            ask rideSharingLink-with this [die] ;; 顺风车司机解除当前乘客（第一个乘客）的link,此时只剩下第二个乘客

            ;; debug
            show "current link die"

            set occupiedNum occupiedNum - 1


            ;; 后退一步
            fd -1

            ;; 前往第二个乘客的目的地
            let otherPassenger one-of rideSharingLink-neighbors ;; 得到第二个乘客

            if otherPassenger = nobody [
              show "debug!!In passenger-on-off function, otherPassenger = nobody"
            ]
            ;; 对于第二个乘客
            ask otherPassenger [
              set-path          ;; 重新寻路

              face first path


              set time time - 1 ;; time变成0
                                ;; 取消静止（以便乘客移动）
              set still? false
            ]





          ][
            ;; 只有一个乘客在车上，则司机让乘客下车后可以自由移动了
            if occupiedNum = 1 [

              ;; 若为当前乘客的目的地

              ask rideSharingLink-with this [die] ;; 当前乘客与司机的link删除 （不能是所有link删除！！）

              ;; debug
              show "current link die"

              ;

              set occupiedNum  occupiedNum - 1 ;;

              ;; 顺风车司机开始自由移动(若此时orderedNum>0,则继续接客；如果没有，就去司机自己的目的地)

              set still?       false
              set-path
              face first path

            ]
          ]


        ]
      ]
    ]

  ]

end

;;
to set-max-speed [avg-max-speed]
  set max-speed           random-normal avg-max-speed (avg-max-speed * 0.1) ;; random-normal mean standard-deviation 根据均值mean返回服从相应分布的随机数，对正态分布还要给出标准差standard-deviation
  if max-speed <= 0       [ set max-speed avg-max-speed ]
end

;; 设置当前主体的速度
to set-speed
  ;; agent can only see one patch ahead of it
  let controller      self
  let this            one-of map-link-neighbors ;; this为连接mapping-citizen结点的结点.如：(citizen 1253): (mapping-citizen 1254)
  ;; show this
  let my-taxi         self   ;;taxi和controller都是当前的主体
  let turtles-ahead   nobody ;; 前面的主体
  let vehicles-ahead  nobody ;; 前面的车队
  let jam-ahead       nobody ;; 前面的堵塞
  let nearest-vehicle nobody ;; 最近的车辆
  let safe-distance   100    ;; positive infinity  安全距离，初始化时为正无穷

  if (count taxi-link-neighbors > 0)[ ;; 若有出租车
    set my-taxi       one-of [map-link-neighbors] of one-of taxi-link-neighbors ;; 从taxi-link的主体中选出任意一个的任意一个map-link-neighbor
  ]

  ;; todo:顺风车

  ifelse patch-ahead 1 != nobody [ ;; 若不是边界（patch-ahead: 返回沿调用海龟当前方向前方给定距离处的单个瓦片。如果超出世界范围，瓦片不存在，则返回nobody）
    set turtles-ahead (turtle-set (other turtles-here) (turtles-on patch-ahead 1)) ;; 将前方patch上的所有海龟和当前主体所在地块的除了当前主体的其他海龟作为一个turtle set (turtle-set value1 value2 ...为一个并集的关系，参数可以为多个)
    with [who != [who] of this and who != [who] of my-taxi]  ;; not my mapping vehicle or my taxi
  ][ ;; 若为边界
    set turtles-ahead turtle-set (other turtles-here) ;; 将当前主体之外的其他海龟作为一个turtle-set
    with [who != [who] of this and who != [who] of my-taxi]
  ]

  ;;;
  ;;;if turtles-ahead != nobody [ ;; 若前方没有海龟
  ;;;  set vehicles-ahead turtles-ahead with[
  ;;;    (shape = "car top" or shape = "van top" or shape = "bus")  ;; private car, taxi and bus ;; 设置vehicle-ahead为前方的私家车、出租车和公交车
  ;;;  ]
  ;;; ]
  ;;; ifelse (vehicles-ahead != nobody and count vehicles-ahead > 0 and any? vehicles-ahead with [distance this = 0])[ ;; 若前方有车，且存在与当前主体距离为0的海龟 （distance agent/patch：返回本主体与给定海龟或瓦片的距离）
  ;;; ifelse speed != 0 [  ;; 若当前主体速度不为0
  ;;;    set speed random-float speed ;; 设置速度小于原来速度(random-float number:如果number为正，返回大于等于0、小于number的一个随机浮点数) 该语句意思为lim_(distance->0) speed = 0
  ;;;  ][ ;; 若为0
  ;;;    set speed random-float person-speed  ;; restart 设置速度为人的速度
  ;;;  ]
  ;;;][;; 若不存在与当前主体距离为0的海龟
  ;;;  if (vehicles-ahead != nobody and count vehicles-ahead > 0) [  ;; 若前方有车
  ;;;    set jam-ahead vehicles-ahead with[ ;; 设置jam-ahead为前方车队集合，这个集合要满足：
  ;;;      abs (abs ([heading] of this - towards this) - 180) < 1 and  ;; in front of self 该车在主体前方（towards agent 返回从本主体到给定主体的方向）
  ;;;      abs (heading - [heading] of this) < 1                       ;; same direction   且属于同一方向
  ;;;    ]
  ;;;    if (jam-ahead != nobody and count jam-ahead > 0) [ ;; 若找到该jam-ahead车队集合
  ;;;      set nearest-vehicle min-one-of jam-ahead [distance this] ;; 找到jam-ahead里距离当前主体最近的车辆
  ;;;      set safe-distance distance nearest-vehicle ;; 设置安全距离为jam-ahead里前方最近的车辆的距离
  ;;;    ]
  ;;;  ]
  ;;;

    ;;  slow down before the red light
    ;;;if (patch-ahead 1 != nobody and [pcolor] of patch-ahead 1 = 19)[ ;; 若前方为红灯
    ;;;  let red-light-distance (distance patch-ahead 1) ;; 计算前方红灯的距离
    ;;;  if (red-light-distance < safe-distance)[ ;; 若小于安全距离
    ;;;    set safe-distance red-light-distance ;; 则设置安全距离为前方红灯距离
    ;;;  ]
    ;;;]

    ifelse safe-distance < buffer-distance [ ;; 若安全距离小于默认安全车距
      set speed 0 ;; 立即停止
    ][ ;; 若大于默认安全距离
      set safe-distance safe-distance - buffer-distance ;; 设置安全距离为其两者之差
      ifelse speed > safe-distance[                  ;;  decelerate：若一个tick的速度大于安全距离，减速
        let next-speed speed - deceleration ;; 下一个tick的速度为当前speed减去减速度
        ifelse (next-speed < 0)[ ;; 若小于0
          set speed 0 ;; 立即停止
        ][ ;; 若大于0
          set speed next-speed ;; 减速
        ]
      ][ ;; 若一个tick的速度小于安全距离，加速直到达到最大速度
        if speed + acceleration < safe-distance[ ;;  accelerate
          let next-speed speed + acceleration
          ifelse (next-speed > max-speed)[
            set speed max-speed
          ][
            set speed next-speed
          ]
        ]
      ]
    ]

end

;; 控制居民出行和工作、休息时间，控制私家车、出租车休息时间（set-duration是在到达目的地调用的）
to set-duration
  ifelse (trip-mode = 1 or trip-mode = 2 or trip-mode = 3 or trip-mode = 6)[           ;; 若主体为居民
    ;;  record 处理记录数据
    ifelse last-commuting-time = nobody [                             ;; 若上次保存的通勤时间为null（尚未初始化）
      set last-commuting-time commuting-counter                       ;; 设置上次保存的通勤时间为通勤计次
    ][                                                                ;; 若通勤时间不为null
      set last-commuting-time commuting-counter - event-duration      ;; 设置上次保存的通勤时间为通勤计次减事件循环时间
    ]
    set   commuting-counter   0

    ;;  halt
    halt event-duration ;; 在公司，停止

    ;; 记录上次呆的地方
      ifelse patch-here = [patch-here] of residence [
        set lastStayAt 0
      ][
        if patch-here = [patch-here] of company [
          set lastStayAt 1
        ]
      ]


  ][
    ;; 出租车
    ifelse (trip-mode = 4)[                 ;; taxi在到达目的地后等待一段时间再出发
      halt taxi-duration
    ][
      ;;　公交车
      if (trip-mode = 5)[                   ;; bus
        halt bus-duration
      ]

      ;; 顺风车（司机）
      if (trip-mode = 7)[
        ifelse (patch-here != [patch-here] of residence and patch-here != [patch-here] of company) [
          ;;show "not company!"
          halt taxi-duration ;; 到达乘客的目的地，等待taxi-duration再出发
        ][
          ;; debug
          show "Driver: It is my company/residence! I'm gonna start working/relaxing"

          set pathList [] ;; 清空pathList

          halt event-duration ;; 顺风车司机到达公司，开始工作

          ;; 记录上次待的地方
          ifelse [patch-here] of residence = patch-here [
            set lastStayAt 0
          ][
            if [patch-here] of company = patch-here [
              set lastStayAt 1
            ]
          ]


        ]
      ]
    ]
  ]
end

;; 设置居民预先的形状
to set-static-shape
  if breed = citizens [
    ask map-link-neighbors [
      set shape "person business"
    ]
  ]
end

;; 由setup-citizens调用，将controller下的map-link-neighbors也就是交通工具（私家车）初始化形状
;; todo:顺风车的形状
to set-moving-shape
  if trip-mode = 1 [
    ask map-link-neighbors [
      set shape "car top"
    ]
  ]

  if trip-mode = 7 [
    ask map-link-neighbors [
      set shape "car"
      set color orange
    ]
  ]

end

;; 确定出行方式，调用者为citizens，输入出行距离和工作时间
to-report getTravelMethod [dist myWorkTime]
  ;; 出行方式：1 私家车 2 公交车 3 出租车 4 顺风车(乘客) 5 地铁 6 短途自行车 7 顺风车(司机)

  ;; 使用array保存效益，返回最大效益的下标
  let benefitArr array:from-list n-values 7 [0]

  ;; 权重计算
  let lambda 0.677 * income + 0.156 * hasCar + 0.167 * education
  let mu -0.34 * age + 0.642 * income + 0.063 * occupation + 0.635 * hasCar
  let omega -0.171 * sex + 0.012 * income + 1.159 * education

  if has-car? = true [
    ;; 计算私家车的效益
    let carS  1
    let carTC (dist / 60 - dist / 26.31) * 1.5
    let carM dist * 7.5 * 7 / 100 + 4 * 2.2 * workTime

    array:set benefitArr 0 mu * carS / (lambda * carTC + omega * carM)
  ]


  ;; 计算公交车的效益
  let busS  1 - (2.4 / 2.5) ^ 5
  let busTC 6 / 60 + dist / 16 - dist / 20
  let busM nobody
  if dist > 0 and dist <= 10 [
    set busM 2
  ]
  if dist > 10 and dist <= 15 [
    set busM 3
  ]
  if dist > 15 and dist <= 20 [
    set busM 4
  ]
  if dist > 20 and dist <= 25 [
    set busM 5
  ]
  if dist > 25 and dist <= 30 [
    set busM 6
  ]
  if dist > 30 and dist <= 35 [
    set busM 7
  ]
  if dist > 35 and dist <= 40 [
    set busM 8
  ]
  if dist > 40 [
    set busM 9
  ]

  array:set benefitArr 1 mu * busS / (lambda * busTC + omega * busM)

  ;; 计算出租车效益
  let taxiS  1
  let taxiTC (3 / 60 + dist / 60 - dist / 26.31) * 1.3

  let taxiM nobody
  if dist > 0 and dist <= 3 [
    set taxiM 10
  ]
  if dist > 3 and dist <= 15 [
    set taxiM 10 + 2 * (dist - 3)
  ]
  if dist > 15 [
    set taxiM 10 + 24 + 3 * (dist - 15)
  ]

  array:set benefitArr 2 mu * taxiS / (lambda * taxiTC + omega * taxiM)

  ;; 计算顺风车效益
  ifelse has-car? = false [ ;; 若无车，则计算顺风车乘客的效益
    let rideSharePassengerS  1
    let rideSharePassengerTC (5 / 26.31 + dist / 60 - dist / 26.31) * 1.3

    let rideSharePassengerM nobody
    if dist > 0 and dist <= 12 [
      set rideSharePassengerM 6.5 + dist * 1.3
    ]
    if dist > 12 and dist <= 40 [
      set rideSharePassengerM 6.5 + 12 * 1.3 + (dist - 12) * 1.6
    ]
    if dist > 40 and dist <= 100 [
      set rideSharePassengerM 6.5 + 12 *　1.3 + 28 * 1.6 + (dist - 40) * 1.3
    ]
    if dist > 100 [
      set rideSharePassengerM 6.5 + 12 *　1.3 + 28 * 1.6 + 60 * 1.3 + (dist - 100) * 0.5
    ]

    array:set benefitArr 3 mu * rideSharePassengerS / (lambda * rideSharePassengerTC + omega * rideSharePassengerM)
  ][
    ;; 若有车，计算乘客效益和司机效益
    let rideSharePassengerS  1
    let rideSharePassengerTC (5 / 26.31 + dist / 60 - dist / 26.31) * 1.3

    let rideSharePassengerM nobody
    if dist > 0 and dist <= 12 [
      set rideSharePassengerM 6.5 + dist * 1.3
    ]
    if dist > 12 and dist <= 40 [
      set rideSharePassengerM 6.5 + 12 * 1.3 + (dist - 12) * 1.6
    ]
    if dist > 40 and dist <= 100 [
      set rideSharePassengerM 6.5 + 12 *　1.3 + 28 * 1.6 + (dist - 40) * 1.3
    ]
    if dist > 100 [
      set rideSharePassengerM 6.5 + 12 *　1.3 + 28 * 1.6 + 60 * 1.3 + (dist - 100) * 0.5
    ]

    let rideShareDriverS 1
    let rideShareDriverTC (5 / 26.31 + dist / 60 - dist / 26.31) * 1.3
    ;; 司机至少期望能接到一个乘客拼车，故其期望费用减去一个乘客的费用
    let rideShareDriverM dist * 7.5 * 7 / 100 + 4 * 2.2 * workTime - rideSharePassengerM + 0.1 * rideSharePassengerM

    array:set benefitArr 6 mu * rideShareDriverS / (lambda * rideShareDriverTC + omega * rideShareDriverM)
  ]

  ;; 计算地铁效益
  let subwayS  1 - (1 / 1.2) ^ 5
  let subwayTC 0.1
  let subwayM nobody
  if dist > 0 and dist <= 6 [
    set subwayM 3
  ]
  if dist > 6 and dist <= 12 [
    set subwayM 4
  ]
  if dist > 12 and dist <= 22 [
    set subwayM 5
  ]
  if dist > 22 and dist <= 32 [
    set subwayM 6
  ]
  if dist > 32 and dist <= 52 [
    set subwayM 7
  ]
  if dist > 52 and dist <= 72 [
    set subwayM 8
  ]
  if dist > 72 and dist <= 92 [
    set subwayM 9
  ]
  if dist > 92 [
    set subwayM 9 + round (dist - 92) / 20 ;; 每超过20公里增加1元
  ]

  array:set benefitArr 4 mu * subwayS / (lambda * subwayTC + omega * subwayM)

  ;; 计算短途自行车效益
  ;; 默认每个居民都有自行车

  let bikeS  nobody

  ;; 自行车的实际出行时间、自行车TC计算
  let tReal nobody
  let bikeTC nobody
  ifelse dist <= 4 [
    set tReal dist / 16
    set bikeTC 0
  ][
    set tReal 4 / 16 + ( dist - 4 ) / 12
    set bikeTC (4 / 16 + 1 / 12 * ( dist - 4 ) - dist / 16) * 0.5
  ]

  set bikeS 1 - ( tReal / 0.5 ) ^ 2

  let bikeM 0

  ;; 解决零除问题
  ifelse lambda * bikeTC + omega * bikeM = 0 [
    array:set benefitArr 5 10000
  ][
    array:set benefitArr 5 mu * bikeS / (lambda * bikeTC + omega * bikeM)
  ]


  ;; 找出数组中最大元素，即最大效益
  let i 0
  let tempMax 0
  let tempMaxIndex 0

  while [i < 7][
    if array:item benefitArr i > tempMax [
      set tempMax array:item benefitArr i
      set tempMaxIndex i
    ]
    set i i + 1
  ]

  report (tempMaxIndex + 1)

end

;; 设置出行方式（可从这里修改代码）
;; todo:顺风车mode
to set-trip-mode
  if breed = citizens [ ;; 只有一个判断
    ;; 如果当前patch为公司或住所
    if [land-type] of patch-here = "residence" or [land-type] of patch-here = "company" [
      let departure   one-of vertices-on patch-here ;; 居民所在位置设为起点

      let destination nobody
      ifelse [land-type] of patch-here = "residence" [
        set destination one-of vertices-on company ;; 居民的公司设为终点
      ][
        set destination one-of vertices-on residence ;; 居民的住所设为终点
      ]

      let dist length find-path departure destination 1
      ;; 进行出行方式选择
      set travelMethod getTravelMethod dist workTime
      ;;show travelMethod 调试
    ]

    ;; 若为刚刚初始化
    ifelse lastTripMode = 0 [
      ;; 若选择私家车（1）出行且有车 todo:顺风车（司机）
      if travelMethod = 1 [
        if has-car? = true [
          set trip-mode 1
          set-max-speed car-speed

          set lastTripMode 1
        ]
      ]

      ;; 若选择顺风车（司机）出行
      if travelMethod = 7 [
        set trip-mode 7
        set-max-speed car-speed

        set lastTripMode 7
      ]

      ;; 若选择出租车（3）出行
      if travelMethod = 3 [ ;; 若出行方式为出租车
        let target-taxi find-taxi ;; 找出租车，赋给target-taxi
        ifelse (target-taxi != nobody) [ ;;若找到出租车
          let this self ;;self为citizen
          ask target-taxi [
            ;;  taxi is already on the patch of passenger
            ifelse (patch-here != [patch-here] of this)[ ;; 当出租车不在在乘客的瓦片上时
              let departure   one-of vertices-on patch-here ;; 出租车所在位置设为起点
              let destination one-of vertices-on [patch-here] of this ;; 乘客所在位置设为终点
              set path        find-path departure destination 4 ;; 寻路，返回一个路径顶点集合
              face first path ;; 将乘客朝向指向第一个路径顶点
            ][ ;; 当出租车在在乘客的瓦片上时
              set path [] ;; 重新设置出租车的的路径属性为空列表
            ]
            set is-ordered? true ;; 设置该出租车为is-ordered属性为true
            create-taxi-link-with this [ ;; 设置连接乘客和的taxi-link (在未到达当前地块是就已连接link，在到达地块后才绑定)
              set shape     "taxi-link-shape" ;; shape为一个字符串
              set color     sky ;; 颜色为天蓝色
              set thickness 0.05 ;; 厚度
            ]
          ]
          set trip-mode 3 ;; 3为take taxi
          set-max-speed car-speed ;; 居民带着移动

          set lastTripMode 3
        ][;; 若没找到出租车
          set trip-mode 2 ;; 设置出行方式为乘公交车
          set-max-speed person-speed

          set lastTripMode 2
        ]
      ]

      ;; 若选择顺风车（乘客）（4）方式出行 todo:
      if travelMethod = 4 [
        let targetDriver findRideDriver ;; 找顺风车司机
        ifelse (targetDriver != nobody) [ ;;若找到司机
          let this self ;;self为citizen

          ;; 对于顺风车司机
          ask targetDriver [
            ;;  检查司机是否已到达（在）乘客的出发地
            ifelse (patch-here != [patch-here] of this)[ ;; 当司机不在在乘客的瓦片上时
              let departure   one-of vertices-on patch-here ;; 司机所在位置设为起点
              let destination one-of vertices-on [patch-here] of this ;; 乘客所在位置设为终点




              let newPassengerPath find-path departure destination 6 ;; 顺风车乘客的trip-mode为6

              set pathList lput newPassengerPath pathList ;; 在pathList添一项当前乘客的路径

              set orderedNum orderedNum + 1

              ;; 若只有一个乘客预定
              ifelse orderedNum = 1 [
                ;; 设置顺风车司机的路径
                set path find-path departure destination 7
                face first path ;; 顺风车司机朝向指向第一个路径顶点


                set isOrdered? true ;; 设置顺风车司机的isOrdered属性为true
                create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                  set shape     "rideSharingLink-shape" ;; shape为一个字符串
                  set color     orange ;; 颜色为橙色
                  set thickness 0.05 ;; 厚度

                  ;; debug
                  show "1Order, linked"
                ]

              ][
                ;; 若有两个乘客
                if orderedNum = 2 [
                  ;; 此时已添加这个第二个乘客的顺风车乘客的路径进入pathList
                  ;; set isOrdered? true ;; 设置顺风车为isOrdered属性为true(设置过了，不用设置)
                  create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                    set shape     "rideSharingLink-shape" ;; shape为一个字符串
                    set color     orange ;; 颜色为橙色
                    set thickness 0.05 ;; 厚度

                    show "2Order, linked"
                  ]

                ]


              ]


            ][
              ;; 当司机在在乘客的瓦片上时，即乘客的出发地和司机的一样
              ;; todo: 此处存疑

              ;; debug
              show　"set-trip-mode, driver is on the patch of passenger"


              ;;

              set orderedNum orderedNum + 1

              ;; 若只有一个乘客
              ifelse orderedNum = 1 [


                set isOrdered? true ;; 设置顺风车司机的isOrdered属性为true
                create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                  set shape     "rideSharingLink-shape" ;; shape为一个字符串
                  set color     orange ;; 颜色为橙色
                  set thickness 0.05 ;; 厚度

                  ;; debug
                  show "1Order, linked"
                ]

              ][
                ;; 若有两个乘客
                if orderedNum = 2 [

                  create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                    set shape     "rideSharingLink-shape" ;; shape为一个字符串
                    set color     orange ;; 颜色为橙色
                    set thickness 0.05 ;; 厚度

                    show "2Order, linked"
                  ]

                ]


              ]



            ]
          ]
          set trip-mode 6 ;; trip-mode为6表示顺风车（乘客）
                          ;; show ("find Driver")
          set-max-speed car-speed

          set lastTripMode 6
        ][;; 若没找到顺风车
          set trip-mode 2 ;; 设置出行方式为乘公交车
                          ;;show ("not found Driver")
          set-max-speed person-speed

          set lastTripMode 2
        ]
      ]
      ;; todo 待完善，完成各个主体开发后（地铁和短途自行车）
      if travelMethod = 2 or travelMethod = 5 or travelMethod = 6 [
        set trip-mode 2 ;; 设置出行方式为乘公交车
        set-max-speed person-speed

        set lastTripMode 2
      ]

    ][
      ;; 若已有上次出行模式
      ;; 若选择私家车（1）出行且有车
      if has-car? = true [
        ;; 若上次出行不是私家车和顺风车司机
        if (lastTripMode != 1 and lastTripMode != 7) [
          if patch-here != [patch-here] of residence [
            if (travelMethod = 1 or travelMethod = 7) [
              set trip-mode 2 ;; 设置出行方式为乘公交车
              set-max-speed person-speed

              set lastTripMode 2
            ]
          ]
        ]
      ]

      ;; 若选择出租车（3）出行
      if travelMethod = 3 [ ;; 若出行方式为出租车
        let target-taxi find-taxi ;; 找出租车，赋给target-taxi
        ifelse (target-taxi != nobody) [ ;;若找到出租车
          let this self ;;self为citizen
          ask target-taxi [
            ;;  taxi is already on the patch of passenger
            ifelse (patch-here != [patch-here] of this)[ ;; 当出租车不在在乘客的瓦片上时
              let departure   one-of vertices-on patch-here ;; 出租车所在位置设为起点
              let destination one-of vertices-on [patch-here] of this ;; 乘客所在位置设为终点
              set path        find-path departure destination 4 ;; 寻路，返回一个路径顶点集合
              face first path ;; 将乘客朝向指向第一个路径顶点
            ][ ;; 当出租车在在乘客的瓦片上时
              set path [] ;; 重新设置出租车的的路径属性为空列表
            ]
            set is-ordered? true ;; 设置该出租车为is-ordered属性为true
            create-taxi-link-with this [ ;; 设置连接乘客和的taxi-link (在未到达当前地块是就已连接link，在到达地块后才绑定)
              set shape     "taxi-link-shape" ;; shape为一个字符串
              set color     sky ;; 颜色为天蓝色
              set thickness 0.05 ;; 厚度
            ]
          ]
          set trip-mode 3 ;; 3为take taxi
          set-max-speed car-speed ;; 居民带着移动

          set lastTripMode 3
        ][;; 若没找到出租车
          set trip-mode 2 ;; 设置出行方式为乘公交车
          set-max-speed person-speed

          set lastTripMode 2
        ]
      ]

      ;; 若选择顺风车（乘客）（4）方式出行 todo:
      if travelMethod = 4 [
        let targetDriver findRideDriver ;; 找顺风车司机
        ifelse (targetDriver != nobody) [ ;;若找到司机
          let this self ;;self为citizen

          ;; 对于顺风车司机
          ask targetDriver [
            ;;  检查司机是否已到达（在）乘客的出发地
            ifelse (patch-here != [patch-here] of this)[ ;; 当司机不在在乘客的瓦片上时
              let departure   one-of vertices-on patch-here ;; 司机所在位置设为起点
              let destination one-of vertices-on [patch-here] of this ;; 乘客所在位置设为终点




              let newPassengerPath find-path departure destination 6 ;; 顺风车乘客的trip-mode为6

              set pathList lput newPassengerPath pathList ;; 在pathList添一项当前乘客的路径

              set orderedNum orderedNum + 1

              ;; 若只有一个乘客预定
              ifelse orderedNum = 1 [
                ;; 设置顺风车司机的路径
                set path find-path departure destination 7
                face first path ;; 顺风车司机朝向指向第一个路径顶点


                set isOrdered? true ;; 设置顺风车司机的isOrdered属性为true
                create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                  set shape     "rideSharingLink-shape" ;; shape为一个字符串
                  set color     orange ;; 颜色为橙色
                  set thickness 0.05 ;; 厚度

                  ;; debug
                  show "1Order, linked"
                ]

              ][
                ;; 若有两个乘客
                if orderedNum = 2 [
                  ;; 此时已添加这个第二个乘客的顺风车乘客的路径进入pathList
                  ;; set isOrdered? true ;; 设置顺风车为isOrdered属性为true(设置过了，不用设置)
                  create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                    set shape     "rideSharingLink-shape" ;; shape为一个字符串
                    set color     orange ;; 颜色为橙色
                    set thickness 0.05 ;; 厚度

                    show "2Order, linked"
                  ]

                ]


              ]


            ][
              ;; 当司机在在乘客的瓦片上时，即乘客的出发地和司机的一样
              ;; todo: 此处存疑

              ;; debug
              show　"set-trip mode, driver is on the patch of passenger"


              ;;

              set orderedNum orderedNum + 1

              ifelse orderedNum = 1 [


                set isOrdered? true ;; 设置顺风车司机的isOrdered属性为true
                create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                  set shape     "rideSharingLink-shape" ;; shape为一个字符串
                  set color     orange ;; 颜色为橙色
                  set thickness 0.05 ;; 厚度

                  ;; debug
                  show "1Order, linked"
                ]

              ][
                ;; 若有两个乘客
                if orderedNum = 2 [

                  create-rideSharingLink-with this [ ;; 设置连接乘客和司机的rideshareLink
                    set shape     "rideSharingLink-shape" ;; shape为一个字符串
                    set color     orange ;; 颜色为橙色
                    set thickness 0.05 ;; 厚度

                    show "2Order, linked"
                  ]

                ]


              ]



            ]
          ]
          set trip-mode 6 ;; trip-mode为6表示顺风车（乘客）
                          ;; show ("find Driver")
          set-max-speed car-speed

          set lastTripMode 6
        ][;; 若没找到顺风车
          set trip-mode 2 ;; 设置出行方式为乘公交车
                          ;;show ("not found Driver")
          set-max-speed person-speed

          set lastTripMode 2
        ]
      ]
      ;; todo 待完善，完成各个主体开发后（地铁和短途自行车）
      if travelMethod = 2 or travelMethod = 5 or travelMethod = 6 [
        set trip-mode 2 ;; 设置出行方式为乘公交车
        set-max-speed person-speed

        set lastTripMode 2
      ]

    ]


  ]
end

;; 设置路径，调用者为居民、公交车主体、顺风车主体
;; todo：顺风车添加乘客路径逻辑
to set-path
  let origin-point     nobody
  let terminal-point   nobody
  let mode             0 ;; mode为临时变量

  ;; 居民
  if breed = citizens [

    ;; 顺风车（司机）,在居民下车后、顺风车车主接到乘客后、顺风车车主结束工作后调用
    ifelse trip-mode = 7 [
      set origin-point   one-of vertices-on patch-here ;; 顺风车（司机）
      ;; 若已有1位乘客预定（车主接到大于1的乘客的情况）-- 此时车上只有一位乘客
      ifelse (isOrdered? = true)[
        ;; 只有一个居民预定了（有一个或没有乘客）
        if (orderedNum = 1) [
          ;; 若车上没有乘客
          if occupiedNum = 0 [
            set terminal-point  last (last pathList) ;; 将目的地设置pathList的第一项（即第一个匹配的居民的路径）的最后一个路径结点（即终点），
          ]
          ;; 若车上已经有一个乘客,则这是匹配的第二个乘客
          if occupiedNum = 1 [
            set terminal-point last (last pathList)    ;; 将目的地设置pathList的第二项（即第一个匹配的居民的路径）的最后一个路径结点（即终点），即前往第二位乘客所在地
          ]

          ;; 若有两个乘客？？按理说不可能
          if occupiedNum = 2 [
            show "exception: occupiedNum = 2 and orderedNum = 1"
          ]

        ]
        ;; 有两个居民预定
        if (orderedNum = 2) [
          if occupiedNum = 0 [
            set terminal-point  last (last pathList) ;; 将目的地设置为第二个乘客所在地
          ]
          ;; 不可能出现两个居民预定，车上有一个居民的情况
        ]

      ][ ;; 司机的isOrdered = false的情况

        ;; 若没有被预定
        if (isOrdered? = false) [
          ;; 若上次呆的地方为家
          ifelse lastStayAt = 0 [
            set terminal-point company ;; 将目的地设置为公司
          ][
            ;; 若上次呆的地方为公司
            set terminal-point residence ;; 将目的地设置为家
            ;; debug
            show "Driver leaving my company"
          ]

        ]

      ]

      ifelse (terminal-point = one-of vertices-on patch-here) [ ;; 若到公司或者家
        ;; 若该目的地为家
        ifelse terminal-point = residence [
          set terminal-point company
        ][
          ;; 若该目的地为公司
          set terminal-point residence
        ]
      ][ ;; 若未到目的地
        ;; debug
        if terminal-point = nobody [
          show "debug!! In set-path function, terminal-point = nobody"
        ]
      ]

      set mode           7 ;; 4代表出租车
    ][
      ;; 其他不为顺风车（司机）的居民

      ;; 若为顺风车（乘客）
      ifelse trip-mode = 6 [
        set origin-point   one-of vertices-on patch-here ;; 顺风车（乘客所在地）
        ifelse patch-here = [patch-here] of company or patch-here = [patch-here] of residence [
          ;; 若处于家或公司
          ifelse lastStayAt = 0 [
            set terminal-point company ;; 将目的地设置为公司
          ][
            ;; 若上次呆的地方为公司
            set terminal-point residence ;; 将目的地设置为家
          ]
          set mode           trip-mode
        ][
          ;; 若不处于家或者公司（即在顺风车司机路上）
          set origin-point   one-of vertices-on patch-here
          ;;
          ifelse lastStayAt = 0 [
            set terminal-point company ;; 将目的地设置为公司
          ][
            ;; 若上次呆的地方为公司
            set terminal-point residence ;; 将目的地设置为家
          ]
          set mode           trip-mode
        ]

      ][
        ;; 其他出行方式，保持原有逻辑
        set origin-point   residence
        set terminal-point company
        set mode           trip-mode
      ]

    ]
  ]

  ;; 出租车
  if breed = taxies [
    set origin-point   one-of vertices-on patch-here
    ifelse (is-ordered? = true)[ ;; 若已有预定
      set terminal-point [patch-here] of one-of taxi-link-neighbors ;; 将目的地设置为绑定的居民
    ][
      set terminal-point one-of companies ;; 将目的地设置为某个商业区域
    ]
    ifelse (terminal-point = patch-here) [ ;; 若到达目的地
      set terminal-point one-of vertices-on one-of residences ;; 将目的地设置为某个住所区域
    ][ ;; 若未到目的地
      set terminal-point one-of vertices-on terminal-point  ;;
    ]
    set mode           4 ;; 4代表出租车
  ]

  ;; 公交
  if breed = buses [
    set origin-point   origin-station
    set terminal-point terminal-station
    set mode           5
  ]


  if origin-point = nobody [
   show "dubug!! stay function, origin-point = nobody"
  ]

  ;; 若在出发地，将路径倒置
  if (patch-here = [patch-here] of origin-point)[
    set path find-path origin-point terminal-point mode
  ]
  ;; 若在目的地，将路径倒置
  if (patch-here = [patch-here] of terminal-point)[
    set path find-path terminal-point origin-point mode
  ]
end

;;  basic behavior :
;; 停等行为
to watch-traffic-light
  if ([land-type] of patch-here = "road" and [pcolor] of patch-here = 19)[ ;; 若为红灯则停止
    halt 0
  ]
  if ([land-type] of patch-here = "road" and [pcolor] of patch-here = 69)[ ;; 若为绿灯则启动
    set still? false
  ]
end

;; stay:由citizens bus taxi调用,当still?=true时
;; todo: 顺风车绑定逻辑
to stay
  ;; 若距离移动行为还有一个tick时
  if (time = 1)[


    ;; 当为顺风车（司机）
    if (trip-mode = 7) [
      ;; 不用重新进行出行方式选择
      set-path
      set time time - 1
      set still? false
    ]

    ;; 当trip-mode不为3出租车（乘客）和6顺风车（乘客）时，保持原程序逻辑
    if (trip-mode = 1 or trip-mode = 2 or trip-mode = 4 or trip-mode = 5) [
      ;; set path
      set-trip-mode
      set-path
      ;; 重新进行出行方式选择后，若不是出租车（乘客）和顺风车（乘客）
      if (trip-mode != 3 and trip-mode != 6)[
        set time time - 1
        set still? false
      ]
    ]




    ;; 调用者为居民
    if breed = citizens [
      ifelse (trip-mode = 3)[ ;; 若居民的出行方式为take taxi
        let this      self
        ;; 找到link的出租车
        let link-taxi one-of taxi-link-neighbors
        ;;若出租车已被预定
        if ([is-ordered?] of link-taxi = true)[
          ;; 若出租车已经在居民所在地
          if ([patch-here] of link-taxi = patch-here)[
            ;; 对绑定的出租车
            ask link-taxi [
              halt 0 ;; 出租车的still?设置为true和speed设置为0, time设置为0
              move-to patch-here ;; 将出租车移到瓦片中心
              ;; 设置未被预定，已被占用
              set is-ordered?  false
              set is-occupied? true
              ;; 改变出租车头
              set heading      [heading] of this
            ]
            ;; 无向链绑定（链的end1和end2端点捆绑在一起）根海龟移动时，叶海龟也沿相同的方向移动相同的距离，无向链互为根海龟、叶海龟--让乘客带着出租车移动
            ask one-of my-taxi-links [tie] ;;my-links:返回与调用者连接的所有无向链组成的主体集合。
            ;; 在公司赚钱
            if (patch-here = [patch-here] of company)[
              set money money + earning-power
            ]
            ;; 朝向路径第一个结点
            face first path
            set time time - 1 ;; time变成0,居民开始出行
            ;; 取消静止
            set still? false
          ]
        ]
      ][
        ;; 若居民出行方式为顺风车（乘客）
        if trip-mode = 6 [
          let this      self
          ;; 找到link的顺风车
          let linkDriver one-of rideSharingLink-neighbors

          ;; debug
          if linkDriver = nobody [
            show "debug!! In stay function, when trip-mode = 6, linkDriver = nobody"
          ]

          ;;若顺风车已被该居民预定
          if ([isOrdered?] of linkDriver = true)[

            ;; 若顺风车到达居民所在地
            if ([patch-here] of linkDriver = patch-here and (patch-here = [patch-here] of residence or patch-here = [patch-here] of company)) [
              show "Driver arrived"
              ;; 若只有一个乘客预定
              ifelse [orderedNum] of linkDriver = 1 [

                ;; 若当前居民为第一个乘客，且只有一个预定
                ifelse [occupiedNum] of linkDriver = 0 [
                  ;; 对绑定的出租车
                  ask linkDriver [
                    halt 0 ;; 顺风车的still设置为true和speed设置为0
                    move-to patch-here ;; 将顺风车移到瓦片中心

                    set orderedNum orderedNum - 1

                    ;; 当没有乘客预定时，设置其为false
                    if orderedNum = 0 [
                      set isOrdered?  false
                    ]

                    set occupiedNum  occupiedNum + 1;
                                                    ;; 改变顺风车头
                    set heading      [heading] of this

                    ;; 消除该名乘客路径
                    set pathList but-first pathList
                  ]

                  ;; 对于该乘客
                  ;; 无向链绑定（链的end1和end2端点捆绑在一起）根海龟移动时，叶海龟也沿相同的方向移动相同的距离，无向链互为根海龟、叶海龟
                  ask one-of my-rideSharingLinks [tie]

                  ;; debug
                  show "[orderedNum] of linkDriver = 1 , [occupiedNum] of linkDriver = 0 , tie"

                  ;; 在公司赚钱
                  if (patch-here = [patch-here] of company)[
                    set money money + earning-power
                  ]

                  face first path
                  set time time - 1 ;; time变成0
                                    ;; 取消静止（以便乘客移动）
                  set still? false

                ][
                  ;; 这种情况为车上有第一个乘客，接到第二个乘客的情况
                  ifelse [occupiedNum] of linkDriver = 1 [



                    ;; 对绑定的顺风车
                    ask linkDriver [
                      halt 0 ;; 顺风车的still设置为true和speed设置为0
                      move-to patch-here ;; 将顺风车移到瓦片中心


                      set orderedNum orderedNum - 1

                      ;; 当没有乘客预定时，设置其为false
                      if orderedNum = 0 [
                        set isOrdered?  false
                      ]

                      ;; show "arrived"
                      set occupiedNum  occupiedNum + 1;
                                                      ;; 改变顺风车头
                      set heading      [heading] of this

                      ;; 打补丁
                      ifelse (pathList != [])[
                        set pathList but-first pathList ;; 消除该乘客路径
                      ][
                        ask one-of rideSharingLink-neighbors [
                          set-path          ;; 第一个乘客重新设定路径
                          face first path
                          set time time - 1 ;; time变成0
                                            ;; 取消静止（以便乘客移动）

                          set still? false
                        ]
                      ]

                    ]



                    ;; 无向链绑定（链的end1和end2端点捆绑在一起）根海龟移动时，叶海龟也沿相同的方向移动相同的距离，无向链互为根海龟、叶海龟
                    ask one-of my-rideSharingLinks [tie]

                    show "[orderedNum] of linkDriver = 1 , [occupiedNum] of linkDriver = 1 , tie"


                    ;; 在公司赚钱
                    if (patch-here = [patch-here] of company)[
                      set money money + earning-power
                    ]
                    face first path


                    let passengers [rideSharingLink-neighbors] of linkDriver ;; 得到当前乘客组成的主体集合
                    ask this [
                      let otherPassengers other passengers ;; 得到第一个乘客的主体集合
                      let otherPassenger one-of otherPassengers

                      if otherPassenger = nobody [
                        show "debug!!In stay function, otherPassenger = nobody"
                      ]
                      ;; 对于第一个乘客
                      ask otherPassenger [
                        set-path          ;; 第一个乘客重新设定路径
                        face first path
                        set time time - 1 ;; time变成0
                                          ;; 取消静止（以便乘客移动）

                        set still? false
                      ]
                    ]



                  ][ ;; ifelse [occupiedNum] of linkDriver = 1 [ 的else if
                    ;; 若到达目的地后，有两个乘客在车上？,按理说这种情况不可能发生
                    if [occupiedNum] of linkDriver = 2 [
                      ;; dubug
                      show "exception: stay function, [occupiedNum] of linkDriver = 2"

                    ]
                  ]
                ]



              ][
                ;; 若有两个乘客预定
                if [orderedNum] of linkDriver = 2 [
                  ;; 这种情况occupiedNum必为0，顺风车需要去往第二个乘客所在地

                  ;; 例外：两个乘客都在一个地方的情况
                  let orderedPassengers [rideSharingLink-neighbors] of linkDriver
                  let thisPatch patch-here


                  ;; 对绑定的出租车
                  ask linkDriver [
                    ;; 第一个乘客在到达第一个乘客所在地后顺风车车不用停止
                    move-to patch-here ;; 将顺风车移到瓦片中心



                    ifelse count orderedPassengers with [patch-here = thisPatch] = 2 [
                      show "2 passengers at one patch!"
                      ;; 设置未被预定，已被占用

                      set orderedNum orderedNum - 2

                      ;; 当没有乘客预定时，设置其为false
                      if orderedNum = 0 [
                        set isOrdered?  false
                      ]

                      ;; show "arrived"
                      set occupiedNum  occupiedNum + 2 ;
                                                      ;; 改变顺风车头
                      set heading      [heading] of this



                    ][
                      ;; 若两个乘客不在一个地点
                      ;; 设置未被预定，已被占用

                      set orderedNum orderedNum - 1

                      ;; 当没有乘客预定时，设置其为false
                      if orderedNum = 0 [
                        set isOrdered?  false
                      ]

                      ;; show "arrived"
                      set occupiedNum  occupiedNum + 1;
                                                      ;; 改变顺风车头
                      set heading      [heading] of this

                      set pathList but-first pathList ;; 消除该第一个乘客路径

                      ;;　顺风车设置路径为第二个乘客所在地
                      set-path
                    ]




                  ]

                  ;; 若两个乘客在一个地点
                  ifelse count orderedPassengers with [patch-here = thisPatch] = 2 [
                    ask orderedPassengers [
                      ask rideSharingLink-with linkDriver [tie] ;; 两个乘客都与司机绑定
                    ]
                    ;; ask my-rideSharingLinks [tie] ;; 两个乘客都与司机绑定
                    show "[orderedNum] of linkDriver = 2, tie 2 passengers at once!"
                  ][
                    ;; 若两个乘客不在一个地点
                    ;; 无向链绑定（链的end1和end2端点捆绑在一起）根海龟移动时，叶海龟也沿相同的方向移动相同的距离，无向链互为根海龟、叶海龟
                    ask one-of my-rideSharingLinks [tie]
                    show "[orderedNum] of linkDriver = 2, tie 1 passenger!"
                  ]



                  ;; debug
                  show "[orderedNum] of linkDriver = 2 , tie"

                  ;; 在公司赚钱
                  if (patch-here = [patch-here] of company)[
                    set money money + earning-power
                  ]
                  face first path

                  ;; 让绑定的顺风车离开当前乘客所在地，以规避nextTick的条件判定
                  ask linkDriver [
                    face first path
                    fd 1
                    set still? false
                  ]

                ]
              ] ;;orderedNum = 1 的 else if




            ] ;; 与if ([patch-here] of linkDriver = patch-here and (patch-here = [patch-here] of residence or patch-here = [patch-here] of company)) 配对

          ] ;; if ([isOrdered?] of linkDriver = true)[

        ] ;; if trip-mode = 6


        ;; 除了出租车（乘客）、顺风车（乘客）和顺风车（司机）的其他出行方式
        if trip-mode != 6 and trip-mode != 7[
          if (patch-here = [patch-here] of company)[ ;; 当到达目的地时
            set money money + earning-power
          ]
          face first path
          set-moving-shape ;; 形状变回原样
        ]
      ]
    ]



    ;; bus
    if breed = buses [
      ;; passengers on
      let next-station       first path
      let this               self
      let on-passengers      (citizens-on patch-here) with [first path = next-station and not map-link-neighbor? self]
      let on-passengers-num  count on-passengers
      if (on-passengers-num > 0 and num-of-passengers < bus-capacity)[
        let free-space           bus-capacity - num-of-passengers
        if on-passengers-num > free-space [
          set on-passengers      (n-of free-space on-passengers)
        ]
        ask on-passengers [
          create-bus-link-with this     [ tie ]
          ask one-of map-link-neighbors [ set size 0.5 ]
        ]
      ]
      set num-of-passengers count bus-link-neighbors
      ;; turn around
      if (patch-here = [patch-here] of origin-station or patch-here = [patch-here] of terminal-station) [
        lt 180
      ]
    ]

    ;; taxi
    if breed = taxies [

      ifelse (is-ordered?)[
        ;; 若已被预定，则设置静止
        halt 0

      ][
        ;; 若未被预定（已经占用或无人预定），则设置朝向
        face first path
      ]
    ]

    ;; 顺风车车主
    if trip-mode = 7 [

      ifelse (isOrdered?)[
        ;; 若已被预定，则设置静止
        halt 0
      ][
        ;; 若未被预定（已经占用或无人预定），则设置朝向
        face first path
        set-moving-shape
      ]
    ]

  ]



  ;; 计次
  if time > 1 [
    set time time - 1 ;;time是停止的时间,每次tick减去1
  ]
  ;; 停止时间到，出租车被预订且处于静止状态，则出租车开始移动 (!important)
  if (time = 0 and breed = taxies and is-ordered? = true and still? = true)[
      set still? false
  ]
  ;; 停止时间到，顺风车被预订且处于静止状态，则顺风车开始移动
  if (time = 0 and trip-mode = 6 and isOrdered? = true and still? = true)[
      set still? false
  ]
end

;; 居民、出租车、公交车的移动 由progress调用
;; todo:
to move
  set-moving-shape ;; 设置形状为移动形状
  set-speed ;; 设定当前主体的速度
  set advance-distance speed ;; 设置一次tick的前进距离为speed
  while [advance-distance > 0 and length path > 1] [ ;; 当path列表的数量大于1
    ;;watch-traffic-light
    let next-vertex first path ;; 找到下一个路径结点
    if (distance next-vertex < 0.0001) [ ;; 若主体距离路径下一个结点距离小于0.0001
      set path but-first path ;; 将路径结点列表的第一个剔除
      set next-vertex first path ;; 将下一个结点作为next-vertex
      ;; 处理当前主体的上下车关系
      passengers-on-off
    ]
    ;; 若主体没设置成静止
    ifelse not still? [
      face next-vertex
      ;; 前进
      advance distance next-vertex
    ][
      ;; 不前进
      set advance-distance 0
    ]
  ]

  if (length path = 1)[ ;; 列表的第一个结点为终点(即差一步到达终点)
    while [advance-distance > 0 and length path = 1][
      ;;watch-traffic-light
      ;; 设置该终点为下一个结点
      let next-vertex first path
      face next-vertex
      ifelse (distance next-vertex < 0.0001) [  ;; arrived at destination 到达终点
        set path []
        passengers-on-off
        ;; 静止一段时间：居民工作，休息
        set-duration
        ;; set default shape
        set-static-shape;; 变化形状为静止是的形状
      ][
        advance distance next-vertex
      ]
    ]
  ]
end

;;  uniform controller
to progress

  ;; 顺风车（司机）
  ask citizens with[trip-mode = 7] [
    ;;set commuting-counter commuting-counter + 1 ;; 所有citizens自身的通勤计次加1

    ;;
    ;;watch-traffic-light
    ifelse still? [
      stay
    ][
      move
    ]
  ]

  ;; 居民
  ;; 除了顺风车司机以外的居民
  ask citizens with[trip-mode != 7] [
    set commuting-counter commuting-counter + 1 ;; 所有citizens自身的通勤计次加1

    if (count bus-link-neighbors = 0)[ ;; 当旁边没有公车时
      ;; watch-traffic-light ;; 判断是否在信号灯下并执行相应动作（会设置still）
      ifelse still? [ ;; 若still为true
        stay
      ][ ;; 若不为true则移动
        move
      ]
    ]
  ]
  ;; 出租车
  ask taxies [
    ;; 如果没被占用，就移动；若被占用，就居民带着他移动
    if (is-occupied? = false)[ ;; 若没被占用
      ;;watch-traffic-light
      ifelse still? [
        stay
      ][
        move
      ]
    ]
  ]



  ;; 公交车
  ask buses [
    ;;watch-traffic-light
    ifelse still? [
      stay
    ][
      move
    ]
  ]
end

to change-traffic-light
  ifelse (traffic-light-count = 0)[
    let green-patches patches with [pcolor = 69]
    let red-patches   patches with [pcolor = 19]
    ask green-patches [set pcolor 19]
    ask red-patches   [set pcolor 69]
    set traffic-light-count traffic-light-cycle
  ][
    set traffic-light-count (traffic-light-count - 1)
  ]
end

;;  command
to go
  progress
  mouse-manager
  ;;change-traffic-light
  record-data
  update-plot
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interaction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 添加居民
to add-citizen
  let my-residence one-of (residences with [num < residence-capacity])
  if (my-residence = nobody)[
    let new-residence one-of residence-district with [land-type = "idle-estate"]
    ask new-residence [
      set land-type "residence"
      set pcolor    yellow
      set num       0
      sprout-vertices 1 [
        setup-graph
        hide-turtle
      ]
    ]
    set residences (patch-set residences new-residence)
    set my-residence new-residence
  ]
  ask my-residence [
    sprout-citizens 1 [
      setup-citizen
      if (trip-mode = 3)[
        halt 2  ;; wait for the taxi
      ]
    ]
    set num num + 1
  ]
end

;; 添加出租车
to add-taxi
  ask one-of companies [ ;; 出租车生成于某公司
    let taxi-heading         0
    let controller           nobody
    sprout-taxies 1 [
      ;;  transportation
      let departure          one-of vertices-on patch-here ;; 出发点为该公司
      let destination        one-of companies ;; 终点为某公司
      ifelse (destination = patch-here) [ ;; 若这个终点和出发点一样
        set destination      one-of vertices-on one-of residences ;; 设置为某一居民区
      ][
        set destination      one-of vertices-on destination ;; 若不一样则不变
      ]
      set trip-mode          4
      set path               find-path departure destination trip-mode
      set-max-speed          car-speed

      ;;  round
      set is-ordered?        false
      set is-occupied?       false
      set speed              0
      set still?             false
      set time               0
      ;; set parameters for the mapping taxi
      face first path
      set taxi-heading       heading
      set controller         self
      hide-turtle            ;; debug
    ]
    ;; 视图层的taxi
    sprout-mapping-taxies 1 [
      set shape              "van top"
      set color              yellow
      set heading            taxi-heading
      rt 90
      fd 0.25
      lt 90
      create-map-link-with   controller [tie]
    ]
  ]
end

;; 添加公交站点
to add-bus-stop
  ;; setup
  ask global-origin-station [
    set land-type "bus-stop"
  ]
  ask global-terminal-station [
    set land-type "bus-stop"
  ]
  let origin-station-vertex   one-of vertices-on global-origin-station
  let terminal-station-vertex one-of vertices-on global-terminal-station
  ;; Create bus line
  let bus-path find-path origin-station-vertex terminal-station-vertex 1
  let bus-line filter [ [node] ->
    ([intersection?] of [patch-here] of node = true) or
    node = terminal-station-vertex
  ] bus-path
  set bus-line fput origin-station-vertex bus-line
  let i 0
  while [i < length bus-line - 1][
    ask item i bus-line [
      create-edge-with item (i + 1) bus-line [
        set bus-route? true
        set cost       10 * person-speed / bus-speed * district-width * length bus-line
        set color      orange
        set thickness  0.2
      ]
    ]
    set i i + 1
  ]
  ;; Create bus
  ask global-origin-station [
    let bus-heading 0
    let controller nobody
    sprout-buses 1 [
      ;; set basic properties
      set origin-station     origin-station-vertex
      set terminal-station   terminal-station-vertex
      ;; set transportation properties
      set num-of-passengers  0
      set-max-speed          bus-speed

      ;; set other properties
      set speed              0
      set still?             false
      set time               0
      set trip-mode          5

      ;; set path
      set path               but-first bus-line

      ;; set parameters for the mapping bus
      face first path
      set bus-heading        heading
      set controller         self
      hide-turtle            ;; debug
    ]
    sprout-mapping-buses 1 [
      set shape              "bus"
      set color              gray + 2
      set size               1.5
      set heading            bus-heading
      rt 90
      fd 0.25
      lt 90
      create-map-link-with   controller [tie]
    ]
  ]
end

;; 鼠标点击事件判断
to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

;; 鼠标点击事件回调函数
to mouse-manager
  let mouse-is-down? mouse-down?
  if mouse-clicked? [
    let patch-clicked patch round mouse-xcor round mouse-ycor
    print "clicked!"  ;; debug
    if ([land-type] of patch-clicked = "road")[
      ifelse (not is-patch? global-origin-station) [
        set global-origin-station patch-clicked
        print patch-clicked  ;; log
      ][
        if (patch-clicked != global-origin-station)[
          set global-terminal-station patch-clicked
          print patch-clicked  ;; log
          add-bus-stop
          set global-origin-station   nobody
          set global-terminal-station nobody
        ]
      ]
    ]
  ]
  set mouse-was-down? mouse-is-down?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Analysis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to record-data
  ;;  taxi
  if count taxies > 0 [
    let average-taxi-carring-rate ((count taxies with [is-occupied? = true] + 0.0) / (count taxies) * 100)
    ifelse is-list? average-taxi-carring-rate-list [
      set average-taxi-carring-rate-list
      fput average-taxi-carring-rate average-taxi-carring-rate-list
    ][
      set average-taxi-carring-rate-list
      (list average-taxi-carring-rate)
    ]
  ]

  ;;  bus
  if count buses > 0[
    let average-bus-carring-number mean [count my-bus-links] of buses
    ifelse is-list? average-bus-carring-number-list [
      set average-bus-carring-number-list
      fput average-bus-carring-number average-bus-carring-number-list
    ][
      set average-bus-carring-number-list
      (list average-bus-carring-number)
    ]
  ]

  ;;  citizen
  if (all? citizens [last-commuting-time != nobody])[
    let average-commuting-time mean [last-commuting-time] of citizens
    ifelse is-list? average-commuting-time-list [
      set average-commuting-time-list
      fput average-commuting-time average-commuting-time-list
    ][
      set average-commuting-time-list
      (list average-commuting-time)
    ]
  ]
end

to update-plot
  if (ticks mod 10 = 0) [
    ;;  taxi
    if is-list? average-taxi-carring-rate-list and (length average-taxi-carring-rate-list >= 100) [
      set-current-plot "Average Taxi Carring Rate"
      plot mean sublist average-taxi-carring-rate-list 0 100
    ]
    ;;  bus
    if is-list? average-bus-carring-number-list and (length average-bus-carring-number-list >= 100) [
      set-current-plot "Average Bus Carring Number"
      plot mean sublist average-bus-carring-number-list 0 100
    ]
    ;;  citizen
    if is-list? average-commuting-time-list and (length average-commuting-time-list >= 100) [
      set-current-plot "Average Commuting Time"
      plot mean sublist average-commuting-time-list 0 100
    ]
  ]
end

to-report analyze-citizen
  ifelse is-list? average-commuting-time-list [
    report mean average-commuting-time-list
  ][
    report 0
  ]
end

to-report analyze-taxi
  ifelse is-list? average-taxi-carring-rate-list [
    report mean average-taxi-carring-rate-list
  ][
    report 0
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Algorithm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dijkstra
to initialize-single-source [ source ]
  ask vertices [
    set weight 10000  ;; positive infinity
    set predecessor nobody
  ]
  if source = nobody [
    show "debug!! In initialize-single-source [ source ] of dijkstra, source = nobody"
  ]
  ask source [
    set weight 0
  ]
end

;; 由迪杰斯特拉算法调用
to relax [u v w]
  let new-weight ([weight] of u + [cost] of w)
  if [weight] of v > new-weight [
    ask v [
      set weight new-weight
      set predecessor u
    ]
  ]
end

;; source 和 target都为vertex?
to dijkstra [source target mode] ;; mode: 1: take car, 2: take bus, 3: take taxi   4: taxi   5: bus
  initialize-single-source source
  let Q vertices
  while [any? Q][
    let u min-one-of Q [weight]
    set Q Q with [self != u]
    let patch-u [patch-here] of u
    ask [edge-neighbors] of u [
      let edge-btw edge [who] of u [who] of self
      ifelse (mode = 5)[       ;; 若为公交车 bus route
        if ([bus-route?] of edge-btw = true)[
          relax u self edge-btw
        ]
      ][                       ;; people commuting
        ifelse ([bus-route?] of edge-btw = true)[
          if (mode = 2) [
            relax u self edge-btw
          ]
        ][
          relax u self edge-btw
        ]
      ]
    ]
  ]
end


;; 寻路算法，使用迪杰斯特拉算法寻找路径，输入为三个参数：起点，终点，和出行方式：1: take car, 2: take bus, 3: take taxi   4: taxi   5: bus 返回路径结点集合
;; source 和 target都为vertex?
to-report find-path [source target mode]
  dijkstra source target mode ;; 使用迪杰斯特拉算法
  let path-list (list target) ;; 创建一个list变量，为多个终点
  if target = nobody [
    show "debug!! In find-path function, target = nobody"
  ]
  let pred [predecessor] of target ;; 将终点的前驱赋给pred变量
  while [pred != source][ ;; 当前驱不是起点，循环
    set path-list fput pred path-list  ;; fput: Add item to the beginning of a list ;; 将当前结点前驱添加到path-list中
    set pred [predecessor] of pred ;; 设置pred变量为前驱的前驱
  ]
  report path-list ;; 返回这个path-list，即结点组成的路径,数据结构为list
end
@#$#@#$#@
GRAPHICS-WINDOW
171
10
716
556
-1
-1
10.96
1
10
1
1
1
0
0
0
1
-24
24
-24
24
1
1
1
ticks
30.0

BUTTON
46
179
114
212
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
46
224
114
257
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
40
268
121
301
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
51
481
108
526
NIL
money
17
1
11

SLIDER
3
10
163
43
initial-people-num
initial-people-num
0
200
200.0
1
1
NIL
HORIZONTAL

BUTTON
43
338
117
371
Add taxi
add-taxi
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
726
63
1015
218
Average Taxi Carring Rate
Time
Rate
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"taxi" 1.0 0 -16777216 true "\n" "\n\n"

MONITOR
725
10
841
55
Number of taxies
count taxies
17
1
11

MONITOR
850
10
966
55
Number of buses
count buses
17
1
11

PLOT
726
228
1015
388
Average Bus Carring Number
Time
Number
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 bus-capacity\n  set-plot-x-range 0 10" ""
PENS
"bus" 1.0 0 -16777216 true "\n\n" "\n"

BUTTON
30
382
131
415
Add citizen
add-citizen
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
725
397
1015
557
Average Commuting Time
Time
Time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"citizen" 1.0 0 -16777216 true "" ""

@#$#@#$#@
## WHAT IS IT?

This is an urban transportation model simulating citizens' commuting by private cars, taxies and buses. It contains four subdivision systems: citizens, taxies, buses and traffic lights. User can manipulate this transportation system by setting the number of citizens, regulating the number of taxies and creating bus lines. This model simulates the real world transportation system which reveals the importance of public traffic.

## HOW IT WORKS

The whole city is presented as grid. There are different kinds of patches: land, road, bus-stop, residence, company and idle-estate. The roads, residences and companies have their corresponding vertices which logically form a graph.

Every citizen has its own residence and company. The citizen's goal is to move back and forth between his residence and his company. If the citizen has a private car, then he commutes by his own car. Otherwise, he either takes taxi if there exists idle one nearby or takes bus. The shortest path from origin to destination will be calculated using Dijkstra Algorithm by the program itself.

All vehicles are running in the two-lane roads and abide by the traffic lights. Vehicles will decelerate when there are other vehicles or red light ahead, and accelerate until reaching the max speed in other situations.

Taxies travel randomly from house to house when idle and buses are driven alongside their bus lines continuously. One taxi can only carry one passenger, meanwhile, one bus can carry up to 4 passengers. Traffic lights switch periodically.

Whether citizens can reach the destination as soon as possible depends on the reasonable planning of public traffic and fewer traffic congestion. User can learn about the utilization of public traffic (taxies and buses) and average commuting time by observing graphical data.

### Patch Color
Land        -- deeper brown
Idle-estate -- deep brown
Residence   -- yellow
Company     -- blue
Road        -- light gray
Red light   -- red
Green light -- green

## HOW TO USE IT

Whole system will be initialized after SETUP button is pressed. After that, user can press the GO button to start the system. 

Taxies can be added by ADD TAXI button. Bus lines can be created by clicking two different road patches when system is running.

### Plots

Average Taxi Carrying Rate  -- displays the proportion of taxies with passenger over time
Average Bus Carrying Number -- displays the average number of passengers on each bus over time
Average Commuting Time      -- displays the average time of each commuting

## THINGS TO NOTICE

Bus lines and taxies have to be added cautiously in case traffic jams happen frequently.

## THINGS TO TRY

User should schedule public traffic so that citizens don't have to walk all the way to the destination which is pretty inefficient and empty loading rate should be reduced to avoid redundant vehicles causing traffic jams.

## EXTENDING THE MODEL

### Vehicle Detection

Limited by the implementation and language capacity, detecting vehicles ahead has low-precision.

### Collision Detection

Since agents don't take up space in NetLogo but their images do, a better way to avoid traffic collision, in the format of image overlapping, is in demand.

### Practical Two-Lane Road

The implementation of two-lane road can be polished, like traffic lights of two directions and integrated turning animation.

### Variety

More vehicle types and terrain can be included.

## NETLOGO FEATURES

Citizens in this model use both utility-based cognition and goal-based cognition.

## RELATED MODELS

- "Traffic Grid": a model of traffic moving in a city grid.

## CREDITS AND REFERENCES

Github: [https://github.com/Luminoid/urban-transportation-system](https://github.com/Luminoid/urban-transportation-system)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bus
true
0
Polygon -7500403 true true 206 285 150 285 120 285 105 270 105 30 120 15 135 15 206 15 210 30 210 270
Rectangle -16777216 true false 126 69 159 264
Line -7500403 true 135 240 165 240
Line -7500403 true 120 240 165 240
Line -7500403 true 120 210 165 210
Line -7500403 true 120 180 165 180
Line -7500403 true 120 150 165 150
Line -7500403 true 120 120 165 120
Line -7500403 true 120 90 165 90
Line -7500403 true 135 60 165 60
Rectangle -16777216 true false 174 15 182 285
Circle -16777216 true false 187 210 42
Rectangle -16777216 true false 127 24 205 60
Circle -16777216 true false 187 63 42
Line -7500403 true 120 43 207 43

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

van top
true
0
Polygon -7500403 true true 90 117 71 134 228 133 210 117
Polygon -7500403 true true 150 8 118 10 96 17 85 30 84 264 89 282 105 293 149 294 192 293 209 282 215 265 214 31 201 17 179 10
Polygon -16777216 true false 94 129 105 120 195 120 204 128 180 150 120 150
Polygon -16777216 true false 90 270 105 255 105 150 90 135
Polygon -16777216 true false 101 279 120 286 180 286 198 281 195 270 105 270
Polygon -16777216 true false 210 270 195 255 195 150 210 135
Polygon -1 true false 201 16 201 26 179 20 179 10
Polygon -1 true false 99 16 99 26 121 20 121 10
Line -16777216 false 130 14 168 14
Line -16777216 false 130 18 168 18
Line -16777216 false 130 11 168 11
Line -16777216 false 185 29 194 112
Line -16777216 false 115 29 106 112
Line -7500403 false 210 180 195 180
Line -7500403 false 195 225 210 240
Line -7500403 false 105 225 90 240
Line -7500403 false 90 180 105 180

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="transportation experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
repeat 6 [add-taxi]</setup>
    <go>go</go>
    <timeLimit steps="6000"/>
    <metric>analyze-citizen</metric>
    <metric>analyze-taxi</metric>
    <enumeratedValueSet variable="initial-people-num">
      <value value="20"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="taxi-detect-distance">
      <value value="4"/>
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="has-car-ratio">
      <value value="0"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traffic-light-cycle">
      <value value="4"/>
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

dotted
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

ridesharinglink-shape
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

taxi-link-shape
0.0
-0.2 0 0.0 1.0
0.0 1 2.0 2.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
