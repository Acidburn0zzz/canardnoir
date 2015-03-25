module WidgetBadge
  module BadgeHelper
    extend ActiveSupport::Concern

    BADGE_FONT_PATH = Rails.root.join('app/assets/fonts/OpenSans-Regular.ttf')
    IMAGE_DIR = Rails.root.join('app/assets/images/widget_logos')

    module ClassMethods
      private

      def setup_blank
        image = MiniMagick::Image.open(IMAGE_DIR.join('OH_Partner_frame.png'))
        image.background('white')
        image
      end

      def new_image
        tempfile = Tempfile.new(['image-base-', '.png'])

        MiniMagick::Tool::Convert.new do |convert|
          yield convert
          convert << tempfile.path
        end

        image = MiniMagick::Image.open(tempfile.path)
        tempfile.close
        image
      end

      def convert_with_delay(convert, seconds, options)
        name = options.delete(:text)
        convert << add_text(name, options).path
        convert.delay(seconds)
      end

      def set_gravity(convert, alignment)
        alignment_options = { right: 'NorthEast', center: 'North', left: 'NorthWest' }
        gravity = alignment_options[alignment] || fail('No alignment specified')
        convert.gravity(gravity)
      end

      def set_font_and_color(convert, options)
        gray = 100 - options[:opacity]

        convert.font BADGE_FONT_PATH
        convert.fill "rgb( #{ gray }%, #{ gray }%, #{ gray }% )"
        convert.stroke options[:stroke]
        convert.pointsize options[:font_size]
        convert.weight options[:weight]
      end
    end
  end
end
