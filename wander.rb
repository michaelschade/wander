#!/usr/bin/env ruby

require 'lifx'
require 'optparse'
require 'timers'

class Wander
  def initialize
    @timers = Timers.new
    @lifx = LIFX::Client.lan
    @lifx.discover!
    @original_colors = {}
  end

  def start_easing!(period: 1)
    @timers.every(period + 0.4) do
      @lifx.lights.each do |light|
        color = eased_color(light)
        light.sine(color, period: period, transient: false)
      end
    end
    loop { @timers.wait }
  end

  private
  def eased_color(light)
    # If we haven't seen this light before, save its color
    unless @original_colors.has_key?(light.id)
      @original_colors[light.id] = light.color
    end
    color = @original_colors[light.id].clone
    variance = Math.sin(Time.now.to_i + color.brightness)/3
    flip = [1, -1].sample
    color.hue = bound_value(color.hue + 15*flip*variance, max: 255)
    color.brightness = bound_value(color.brightness + variance, min: 0.3)
    color
  end

  def bound_value(value, min: 0, max: 1)
    if value < min
      value = min
    elsif value > max
      value = max
    end
    value
  end
end

def main
  options = {
    period: 1
  }

  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: ./wander.rb [options]"

    opts.on("--period N", Float, "Ease lights every N seconds (default 1)") do |period|
      options[:period] = period
    end
  end
  optparse.parse!(ARGV)

  wander = Wander.new
  wander.start_easing!(period: options[:period])
end

if $0 == __FILE__
  main
end
