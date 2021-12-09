require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'



def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def format_time(registration_date)
  Time.strptime(registration_date, '%m/%d/%y %k:%M')
end

def busiest_hour(time)
  most_common_hour = time.each_with_object(Hash.new(0)) { |frequency, result| result[frequency] += 1 }
  "Most common hour is #{most_common_hour.key(most_common_hour.values.max)} with #{most_common_hour.values.max} people"
end

def busiest_weekday(time)
  most_common_weekday = time.each_with_object(Hash.new(0)) { |frequency, result| result[frequency] += 1 }
  "Most common weekday is #{most_common_weekday.key(most_common_weekday.values.max)} with #{most_common_weekday.values.max} people"
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/()[-., ]/, '')
  return phone_number if phone_number.length == 10
  return phone_number[1..10] if phone_number.length == 11 && phone_number[0] == 1

  'Invalid number'
end

puts 'EventManager initialized.'



contents = CSV.open(
  'event_attendees_full.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
array_of_hours = []
array_of_weekdays = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)

  # 30 minutes are added to round the hours
  array_of_hours << (format_time(row[:regdate]) + 1800).hour

  array_of_weekdays << format_time(row[:regdate]).strftime('%A')

  save_thank_you_letter(id, form_letter)
end

puts busiest_hour(array_of_hours)
puts busiest_weekday(array_of_weekdays)