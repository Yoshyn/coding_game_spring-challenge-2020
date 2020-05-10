require_relative './array'

module AttrHistory
  def attr_historized(*attributes)
    Array.wrap(attributes).each do |attribute|
      method_key = "_#{attribute}s"
      store_key  = "@_#{method_key}"

      define_method(method_key) do
        attrs = instance_variable_get(store_key)
        attrs || instance_variable_set(store_key, [])
      end

      define_method(attribute) do
        __send__(method_key).last
      end

      define_method("#{attribute}=") do |value|
        __send__(method_key) << value
      end

      define_method("#{attribute}_changed?") do
        values = __send__(method_key)
        return false if values.count < 2
        return values[-1] != values[-2]
      end

      define_method("previous_#{attribute}") do
        __send__(method_key)[-2]
      end

      define_method("#{attribute}_decreased?") do
        values = __send__(method_key)
        !!(values[-1] && values[-2] && values[-1] < values[-2])
      end

      define_method("#{attribute}_increased?") do
        values = __send__(method_key)
        !!(values[-1] && values[-2] && values[-1] > values[-2])
      end

      define_method("#{attribute}_already_changed?") do
        __send__(method_key).uniq.count > 1
      end
    end
  end
end
