class Jat
  module JatClass
    # Returns the Jat class that this class is namespaced under.
    attr_accessor :jat_class

    # Since class that uses current module is anonymously subclassed when Jat is
    # subclassed, and then assigned to a constant of the Jat subclass, make
    # inspect reflect the likely name for the class.
    def inspect
      return super unless jat_class

      path = to_s
      index = path.rindex("::") + 2
      class_name = path[index, path.length - index]

      "#{jat_class.inspect}::#{class_name}"
    end
  end
end
