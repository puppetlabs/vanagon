# String is generally pretty functional, but sometimes you need
# a couple of small convienence methods to make working with really
# long or really funky strings easier. This will indent all lines
# to the margin of the first line, preserving sunsequent indentation
# while still helping reign in HEREDOCS.
class String
  # @return [String]
  def undent
    gsub(/^.{#{slice(/^\s+/).length}}/, '')
  end
end
