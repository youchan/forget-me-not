require 'sinatra'


get '/' do
  @iframe = "<iframe src=\"https://www.google.com/calendar/embed?mode=WEEK&amp;height=600&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;src=j1cjb6hag0khuducbjlpoq6sj8%40group.calendar.google.com&amp;color=%2388880E&amp;src=7ffhsgeogne8u4flu5s695o5j4%40group.calendar.google.com&amp;color=%23333333&amp;src=youchan01%40gmail.com&amp;color=%232952A3&amp;ctz=Asia%2FTokyo\" style=\" border-width:0 \" width=\"800\" height=\"600\" frameborder=\"0\" scrolling=\"no\"></iframe>"
  erb :index 
end
