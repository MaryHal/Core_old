#!/usr/bin/ruby -w
# encoding: utf-8

require 'watir-webdriver'

require 'highline/import'
require 'json'

class LoginInfo
    attr_accessor :user
    attr_accessor :pass

    def initialize(user = "asdf", pass = "qwerty543")
        @user = user
        @pass = pass
    end

    def read
        @user = ask("Username: ")
        @pass = ask("Password: ") { |q| q.echo = "*" }
    end


    def login(browser)
        browser.text_field(:name, 'user').set(@user)
        browser.text_field(:name, 'pass').set(@pass)
        form = browser.form(:name, 'query')
        form.submit
    end
end

class Course
    attr_accessor :name
    attr_accessor :sln
    attr_accessor :drop

    def initialize(name, sln, drop)
        @name = name
        @sln  = sln
        @drop = drop
    end

    def createUrl
        baseUrl = "https://sdb.admin.washington.edu/timeschd/uwnetid/sln.asp?";
        quarter = "AUT+2012";

        return baseUrl + "QTRYR=" + quarter + "&SLN=" + @sln[0];
    end

    def register(browser)
        browser.goto("https://sdb.admin.washington.edu/students/uwnetid/register.asp")

        if browser.text.include? "You must read and acknowledge"
            raise "Cannot continue with registration. You didn't accept the terms of agreement."
        end

        # We are probably at the register page
        freeSln = /name=\"sln(\d)\" max/.match(browser.html)[1]
        slnInt = Integer(freeSln)

        for i in 0...@sln.length
            browser.text_field(:name, "sln" + (slnInt + i).to_s).set(@sln[i])
        end

        # Actually register
        #form = browser.form(:id, 'regform')
        #browser.text_field(:name, slnField).set(@sln[0])
        #form.submit
    end

    def to_s
        puts "Title: #{@name}", 
             "  Sln: #{@sln}", 
             " Drop: #{@drop}"
             #, createUrl
    end
end

class Core
    attr_accessor :loginInfo
    attr_accessor :courses
    attr_accessor :timeout

    def initialize
        @loginInfo = nil
        @courses   = []
        @timeout   = 30
    end

    def loadCourses(filename)
        file = JSON.parse(IO.read(filename))

        # Load Courses
        file.each_pair do |k,v|
            course = Course.new(k, v["sln"], v["drop"])
            @courses.push(course)
        end

        # Just checking
        @courses.each do |i|
            puts i.to_s
        end
    end

    def run
        @loginInfo = LoginInfo.new
        @loginInfo.read
        browser = Watir::Browser.new

        running = true
        while running
            browser.goto(@courses[0].createUrl)

            if browser.text.include? "log in with your UW"
                puts "Must Log In"
                @loginInfo.login(browser)
                if browser.text.include? "Login failed"
                    raise "Login Failed. Incorrect information."
                end
            elsif browser.text.include? "Open"
                @courses[0].register(browser)
            end
            sleep 10
        end

        browser.close
    end
end

# Main script
if __FILE__ == $0
    core = Core.new
    core.loadCourses("test.json")
    core.run
end

