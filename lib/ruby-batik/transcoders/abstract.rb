module Batik
  module Transcoders
    import org.apache.batik.transcoder.TranscodingHints
    import org.apache.batik.transcoder.TranscoderInput
    import org.apache.batik.transcoder.TranscoderOutput
    import java.awt.Color
    class Abstract
      def self.java_types
        {
          :snapshot_time => Float,
          :pixel_unit_to_millimeter => Float,
          :max_height => Float,
          :max_width => Float,
          :height => Float,
          :width => Float,
        }
      end
      
      def self.default_options
        {
          :execute_onload => nil, # true/false
          :allowed_script_types => nil, # text/ecmascript, application/java-archive
          :constrain_script_origin => nil, # true/false
          :snapshot_time => nil,
          :pixel_unit_to_millimeter => 0.264583, # Size of a px in millimeters
          :user_stylesheet_uri => nil,
          :alternate_stylesheet => nil,
          :default_font_family => nil,
          :media => nil,
          :language => nil,
          :max_height => nil,
          :max_width => nil,
          :height => nil,
          :width => nil,
          :background_color => nil, # Array of RGB ( [255, 255, 255] ) or RGBA ( [255, 255, 255, 255] )

          # Non-Batik options
          :base_uri => nil # Document URI for relative path lookups
        }
      end
      
      def self.transcode(document, options={})
        options = default_options.merge(process_options(options.dup))
        in_io = StringIO.new(document)
        out_io = StringIO.new('','w+b')

        t_input = TranscoderInput.new(in_io.to_inputstream)
        t_input.uri = options.delete(:base_uri)

        transcoder = klass.new
        transcoder.setErrorHandler(Batik::DefaultErrorHandler.new)
        options.each_pair do |key, val|
          next if val.nil?

          value = if key == :background_color
                    if val.count == 3
                      Color.new(val[0], val[1], val[2])
                    else
                      Color.new(val[0], val[1], val[2], val[3])
                    end
                  else
                    val.to_java(java_type_for(key))
                  end

          transcoder.addTranscodingHint(transcoder.class.const_get("key_#{key}".upcase), value)
        end

        transcoder.transcode(t_input, TranscoderOutput.new(out_io.to_outputstream))
        out_io.flush

        # Sometimes this is closed for read. If so, we must use the #string method
        if out_io.closed_read?
          out_io.string
        else
          out_io.rewind
          out_io.read
        end
      end

      private
      
      def self.process_options(options)
        if dpi = options.delete(:dpi)
          options[:pixel_unit_to_millimeter] = 25.4 / dpi
        end

        options
      end
      
      def self.java_type_for(key)
        java_types[key] ? eval("java.lang.#{java_types[key]}") : nil
      end
    end
  end
end
