require 'open-uri'
require 'nokogiri'
require 'json'

srcAirports = ["KTW", "WMI", "WAW", "KRK"]
dstAirports = ["BRU", "CRL"]

depDay = 18
depMonth = 4
depYear = 2020

retDay = 6
retMonth = 5
retYear = 2020

minDays = 5
maxDays = 6





counter = -1
srcAirportsPrep = srcAirports.map { |air| counter+=1; "srcap#{counter}=#{air}" }
srcAirportsStr1 = "%28%2B" + srcAirports.join("%2C") + "%29"
srcAirportsStr2 = srcAirportsPrep.join("&")

counter = -1
dstAirportsPrep = dstAirports.map { |air| counter+=1; "dstap#{counter}=#{air}" }
dstAirportsStr1 = "%28%2B" + dstAirports.join("%2C") + "%29"
dstAirportsStr2 = dstAirportsPrep.join("&")

url = "http://www.azair.eu/azfin.php?searchtype=flexi&tp=0&isOneway=return&srcAirport=#{srcAirportsStr1}&#{srcAirportsStr2}&srcFreeAirport=&srcTypedText=pra&srcFreeTypedText=&srcMC=&dstAirport=#{dstAirportsStr1}&#{dstAirportsStr2}&dstFreeAirport=&dstTypedText=mil&dstFreeTypedText=&dstMC=&depmonth=#{depYear}#{format("%02d", depMonth)}&depdate=#{depYear}-#{format("%02d", depMonth)}-#{format("%02d", depDay)}&aid=0&arrmonth=#{retYear}#{format("%02d", retMonth)}&arrdate=#{retYear}-#{format("%02d", retMonth)}-#{format("%02d", retDay)}&minDaysStay=#{minDays}&maxDaysStay=#{maxDays}&dep0=true&dep1=true&dep2=true&dep3=true&dep4=true&dep5=true&dep6=true&arr0=true&arr1=true&arr2=true&arr3=true&arr4=true&arr5=true&arr6=true&samedep=true&samearr=true&minHourStay=0%3A45&maxHourStay=23%3A20&minHourOutbound=0%3A00&maxHourOutbound=24%3A00&minHourInbound=0%3A00&maxHourInbound=24%3A00&autoprice=true&adults=1&children=0&infants=0&maxChng=1&currency=EUR&indexSubmit=Search"

puts url

html = open(url)

$flights = []

def parse_flight (content)
  dateDep = content.css('.date').inner_html
  timeDep = content.css('.from').at('strong').inner_html
  airportDep = content.css('.from').css('.code').inner_html[0, 3]
  timeArr = content.css('.to').inner_html[0, 5]
  airportArr = content.css('.to').css('.code').inner_html[0, 3]
  price = content.css('.subPrice').inner_html
  durationString = content.css('.durcha').inner_html
  slashIndex = durationString.index(" / ")
  duration = durationString[0, slashIndex]
  changes = durationString[slashIndex + 3, durationString.length]
  # puts "Departure on  #{dateDep} at #{timeDep} from #{airportDep}. Arrival to #{airportArr} at #{timeArr}. Partial price: #{price}"
  return {
    "Departure date": dateDep,
    "Departure time": timeDep,
    "Departure airport": airportDep,
    "Arrival time": timeArr,
    "Arrival airport": airportArr,
    "Duration": duration,
    "Changes": changes,
    "Price": price
  }
end

resultCounter = 0

doc = Nokogiri::HTML(html)
results = doc.css('.result')
results.each { |result|
  resultCounter += 1
  flightThere = nil
  flightBack = nil
  totalPrice = nil
  result.search('p').each { |res|

    if res.inner_html.include? "caption tam"
      # puts "There"
      flightThere = parse_flight(res)
    elsif res.inner_html.include? "caption sem"
      # puts "Back"
      flightBack = parse_flight(res)
    elsif res.inner_html.include? "sumPrice"
      #puts "Total Price: #{res.css('.bp').inner_html}"
      totalPrice = res.css('.bp').inner_html
    end
  }
  $flights.push({There: flightThere, Back: flightBack, "Total price": totalPrice})
}
#puts $flights
puts "Total results: #{resultCounter}"

json = JSON.pretty_generate($flights)
File.open("flights.json", 'w') { |file| file.write(json) }
