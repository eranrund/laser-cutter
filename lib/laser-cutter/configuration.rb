require 'hashie/mash'
require 'prawn/measurement_extensions'
require 'pdf/core/page_geometry'

module Laser
  module Cutter
    class MissingOption < RuntimeError
    end
    class Configuration < Hashie::Mash
      DEFAULTS = {
          units: 'mm',
          page_size: 'LETTER',
          page_layout: 'portrait'
      }

      UNIT_SPECIFIC_DEFAULTS = {
          'mm' => {
              margin: 5,
              padding: 5,
              stroke: 0.0254,
          },
          'in' => {
              margin: 0.125,
              padding: 0.1,
              stroke: 0.001,
          }
      }

      SIZE_REGEXP = /[\d\.]+x[\d\.]+x[\d\.]+\/[\d\.]+\/[\d\.]+/

      FLOATS   = %w(width height depth thickness notch margin padding stroke)
      REQUIRED = %w(width height depth thickness notch file)

      def initialize(options = {})
        options.delete_if{|k,v| v.nil?}
        self.merge!(DEFAULTS)
        self.merge!(options)
        if self['size'] && self['size'] =~ SIZE_REGEXP
          dim, self['thickness'], self['notch'] = self['size'].split('/')
          self['width'],self['height'],self['depth'] = dim.split('x')
          delete('size')
        end
        FLOATS.each do |k|
          self[k] = self[k].to_f if (self[k] && self[k].is_a?(String))
        end
        self.merge!(UNIT_SPECIFIC_DEFAULTS[self['units']].merge(self))
      end

      def validate!
        missing = []
        REQUIRED.each do |k|
          missing << k if self[k].nil?
        end
        unless missing.empty?
          raise MissingOption.new("#{missing.join(', ')} #{missing.size > 1 ? 'are' : 'is'} required, but missing.")
        end
      end

      def all_page_sizes
        unit = 1.0 / 72.0 # PDF units per inch
        multiplier = (self.units == 'in') ? 1.0 : 25.4
        h = PDF::Core::PageGeometry::SIZES
        output = "\n"
        h.keys.sort.each do |k|
          output << sprintf("\t%10s:\t%6.1f x %6.1f\n",
                 k,
                 multiplier * h[k][0].to_f * unit,
                 multiplier * h[k][1].to_f * unit )
        end
        output
      end
    end
  end
end
