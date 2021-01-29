require "google_drive"
require "dotenv"
require_relative "wg_api"

def MakeMemberDataHash(wgapi,clan_ids)
  member_datas={}
  clan_ids.each do |clan_id|
    member_ids_per_clan = MakeMemberIDListPerClan(wgapi, clan_id)
    member_ids_per_clan_str = JoinStrWithPer2C(member_ids_per_clan)
    members_data = wgapi.GetMembersData(member_ids_per_clan_str)
    members_clan = wgapi.GetMembersClan(member_ids_per_clan_str)
    member_ids_per_clan.each do |member_id|
      nickname = {}
      clan = {}
      nickname["nickname"] = members_data["data"]["#{member_id}"]["nickname"]
      p nickname
      clan["clan_id"] = members_clan["data"]["#{member_id}"]["clan_id"]
      p clan
      member_datas[member_id] = nickname.merge(clan)
    end
  end
  return member_datas
end
def MakeMemberIDListPerClan(wgapi,clan_id)
  datas = wgapi.GetClanMembers(clan_id)
  member_ids_per_clan = datas["data"][clan_id]["members_ids"]
  return member_ids_per_clan
end
def MakeMemberNameListPerClan(wgapi,clan_id)
  member_names_per_clan = []
  member_ids_per_clan = MakeMemberIDListPerClan(wgapi, clan_id)
  member_ids_per_clan_str = JoinStrWithPer2C(member_ids_per_clan)
  result = wgapi.GetMembersData(member_ids_per_clan_str)
  member_ids_per_clan.each do |member_id|
    nickname = result["data"]["#{member_id}"]["nickname"]
    member_names_per_clan.push(nickname)
  end
  return member_names_per_clan
end
def NextEmptyColumn(sheet)
  column = 1
  loop do
    if sheet[i,2] == ""
      break
    end
    column += 1
  end
  return column
end
def LastColumn(sheet)
  column = NextEmptyColumn(sheep) - 1
  return column
end
def JoinStrWithPer2C(array)
  result = ""
  array.each do |str|
    result = result + "#{str}" + "%2C"
  end
  result.chomp("%2C")
  return result
end
def UpdateByHash(sheet,member_datas)
  i = 1
  member_datas.each do |member_id, data|
    sheet[i,1] = data["clan_id"]
    sheet[i,2] = data["nickname"]
    sheet[i,3] = member_id
    i += 1
  end
  sheet.save
end
def UpdateVertic(sheet,row,data)
  length = (1..data.length).to_a
  length.each do |num|
    sheet[num,row] = data[num-1]
  end
  sheet.save
end

Dotenv.load
wgapi = WGAPI.new(
  application_id: ENV['APPLICATION_ID'],
  database_url: ENV['DATABASE_URL']
)
session = GoogleDrive::Session.from_config("config.json")
sheet_0 = session.spreadsheet_by_key(ENV['KEY_TEST']).worksheets[0]

clan_ids = ["1845","6800","16297","29274","34796","44817"]

p "initiate test"
member_datas = MakeMemberDataHash(wgapi,clan_ids)
p "hash complete"
UpdateByHash(sheet_0,member_datas)
# p sheet_0[176,1]
# member_ids = MakeMemberIDList(wgapi,clan_ids)
# p "member id ready"
# member_names = MakeMemberNameList(wgapi,clan_ids)
# p "member name ready"
# UpdateVertic(sheet_0,2,member_ids)
# UpdateVertic(sheet_0,1,member_names)
# data = MakeMemberIDList(wgapi)
# UpdateVertic(sheet_0,1,data)
