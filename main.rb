require "google_drive"
require "dotenv"


Dotenv.load
session = GoogleDrive::Session.from_config("config.json")
sheets = session.spreadsheet_by_key(ENV["KEY_TEST"]).worksheets[0]

sheets[1,1] = "hello world!!"
sheets.save
