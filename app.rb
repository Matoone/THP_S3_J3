require 'bundler'
Bundler.require

$:.unshift File.expand_path("./../lib", __FILE__)
require 'app/mairies_scrapper'
require 'open-uri'
require 'json'
require 'google_drive'


emails = MairiesScrapper.new.perform
