module VCR
  extend self

  def version
    @version ||= begin
      string = '1.5.0'

      def string.parts; VCR.version.split('.').map { |p| p.to_i }; end
      def string.major; parts[0]; end
      def string.minor; parts[1]; end
      def string.patch; parts[2]; end

      string
    end
  end
end
