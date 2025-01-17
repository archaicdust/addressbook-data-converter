# # Organization Processor
require! <[fs cheerio]>
require! \./utils

# ### Normalize orgnization name.
# ```
# - @param orgname String organization name.
# - @returns String normalized organization name.
# ```
export function normalized-name(orgname)
  throw "orgname is required." unless orgname
  orgname .=replace /台/g, '臺'
  orgname .=replace /^連江縣/, '福建省連江縣'
  orgname .=replace /鄉鄉民代表會/, '鄉民代表會'
  orgname .=replace /區區公所/, '區公所'
  orgname .=replace /鎮鎮公所/, '鎮公所'
  orgname .=replace /鄉鄉公所/, '鄉公所'
  return '內政部戶政司' if orgname is \內政部戶政司戶政司
  badnames =
    \高雄市那瑪夏區
    \高雄市桃源區
    \高雄市甲仙區
    \高雄市旗山區
    \花蓮縣秀林鄉
    \花蓮縣瑞穗鄉
    \花蓮縣光復鄉
    \花蓮縣玉里鎮
    \桃園縣楊梅市
    \金門縣烏坵鄉
    \金門縣烈嶼鄉
    \金門縣金寧鄉
    \金門縣金沙鎮
  if orgname in badnames then "#{orgname}戶政事務所" else orgname

popololized-record-twgovdata_7307 = (acc, record) -->
  #@FIXME: workround.
  if record.orgcode == '機關代碼'
    return null
  find_other_names = ->
      ret = []
      if record.dissolution_note is \是 and record.new_name isnt ''
        ret.push do
          name: normalized-name record.new_name
          start_date: utils.date_from_rocdate record.dissolution_date
      else if record.dissolution_note is not \是 and record.old_name isnt ''
        ret.push do
          name: normalized-name record.old_name
      ret

  orgname = normalized-name record.name
  acc.data[orgname] = do
    name: orgname
    other_names: find_other_names!
    identifiers: [
        * identifier: record.orgcode
          scheme: \orgcode
    ]
    classification: record.classification
    parent_id: record.parent_orgcode
    founding_date: utils.date_from_rocdate record.founding_date
    dissolution_date: utils.date_from_rocdate record.dissolution_date
    image: null
    contact_details: [
        * label: \機關電話
          type: \voice
          value: record.phone
        * label: \機關傳真
          type: \fax
          value: record.fax
    ]
    links: []
    sources:
      * url: 'http://data.gov.tw/node/7307'
  acc.count += 1

# ### 行政院中央機關及地方機關代碼 Porcessor
# ```
# - @param acc {data:{$orgname:$org}}, count:Int}
# - @param src String
# - @param done Function
# - @returns same as acc
# ```
export function process_twgovdata_7307(acc, src, done)
  opts = do
    columns: do
      orgcode: \機關代碼
      name: \機關名稱
      zipcode: \郵遞區號
      address: \機關地址
      phone: \機關電話
      parent_orgcode: \主管機關代碼
      parent_name: \主管機關名稱
      fax: \傳真
      start_date: \機關生效日期
      dissolution_date: \機關裁撤日期
      # 「機關層級」欄的數字代表該機關隸屬層級，分1至5級。
      # - 1:總統府、國家安全會議、五院。
      # - 2:為1級單位的所屬機關(例如:內政部、外交部…等)，及各縣市政府。
      # - 3:為2級單位的所屬機關。
      # - 4:為3級單位的所屬機關。
      # - 5:為4級單位的所屬機關。
      classification: \機關層級
      dissolution_note: \裁撤註記
      new_orgcode: \新機關代碼
      new_name: \新機關名稱
      new_start_date: \新機關生效日
      old_orgcode: \舊機關代碼
      old_name: \舊機關名稱
  _, count <- utils.from_csv src, opts, popololized-record-twgovdata_7307 acc
  done acc

popololized-record-twgovdata_6119 = (acc, record) -->
  return null if record.area == '地區'
  if '(' in record.name_zh or '（' in record.name_zh
    [_, name_zh, name_en_zh] = record.name_zh.match /(.*)\s*[（(](.*)[)）]/
  else
    name_zh = record.name_zh
  o = do
    name: name_zh
    address: record.address
    other_names: [
      * name: record.name_en
    ]
    contact_details: [
      * label: '電話'
        type: 'voice'
        value: record.phone
      * label: '緊急聯絡電話'
        type: 'voice'
        value: record.ergency_call_zh
      * label: '電子郵件'
        type: 'email'
        value: record.email
      * label: '傳真'
        type: 'fax'
        value: record.fax
    ]
  if acc.data[name_zh]?
    acc.data[name_zh] <<< o
  else
    acc.data[o.name] = o
  acc.count += 1
  o

# ### 駐外館通訊錄 Porcessor
# ```
# - @param acc {data:{$orgname:$org}}, count:Int}
# - @param src String
# - @param done Function
# - @returns same as acc
# ```
export function process_twgovdata_6119(acc, src, done)
  opts = do
    columns: do
      area: \地區
      country: \國家名稱
      name_zh: \館處中文名稱
      name_en: \館處外文名稱
      offdate_id: '駐外館處休假日編號(系統用)'
      url: \網址
      address: '館址(外文)'
      zipcode: \信箱號碼
      phone: \電話
      ergency_call_zh: '緊急聯絡電話(中文)'
      ergency_call_en: '緊急聯絡電話(英文)'
      fax: \傳真
      supvisor_zh: '主管(中文)'
      supvisor_en: '主管(英文)'
      post: \職稱
      email: \EMAIL
      office_hour: \上班時間
      timezone: \時差
      manage_area_zh: '轄區(中文)'
      service_time: \領務服務時間
      post_unit: \所屬單位
      post_source: \消息來源
  _, count <- utils.from_csv src, opts, popololized-record-twgovdata_6119 acc
  done acc


# ### 戶政機關通訊 Porcessor
# ```
# - @param acc {data:{$orgname:$org}}, count:Int}
# - @param src String file path
# - @param done Function
# - @returns same as acc
# ```
export function process_twgovdata_7437(acc, path, done)
  content = fs.readFileSync path, 'utf-8'
  content = content.replace /orgName/g, 'orgname'
  $ = cheerio.load content, {+xmlMode}
  orgs = $ 'orgs' .find 'org'
  get = (o, q) -> o.find q .text!
  orgs.each ->
    obj = do
      name: normalized-name(get @, 'orgname')
      address: get @, 'address'
      other_names: []
      contact_details: [
        {label: '機關電話', 'type': 'voice', 'value': get @, 'tel'}
        {label: '機關電郵', 'type': 'email', 'value': get @, 'email'}
        {label: '機關傳真', 'type': 'fax', 'value': get @, 'fax'}
      ]
      note: get @, 'description'
      links: [
        * url: get @, 'website'
      ]
    unless acc.data[obj.name]?
      acc.data[obj.name] = obj
    else
      acc.data[obj.name] <<< obj
    acc.count += 1
  done acc

# ### 地政事務所通訊 Porcessor
# ```
# - @param acc {data:{$orgname:$org}}, count:Int}
# - @param src String
# - @param done Function
# - @returns same as acc
# ```
export function process_twgovdata_7620(acc, src, done)
  content = fs.readFileSync src, 'utf-8'
  $ = cheerio.load content, {+xmlMode}
  orgs = $ 'channel' .find 'item'
  get = (o, q) -> o.find q .text!
  orgs.each ->
    obj = do
      name: get @, 'title1'
      address: null
      other_names: []
      #@FIXME: parse contact details of node 7620.
      contact_details: []
      note: get @, 'description'
      links: []
    unless acc.data[obj.name]?
      acc.data[obj.name] = obj
    else
      acc.data[obj.name] <<< obj
    acc.count += 1
  done acc
