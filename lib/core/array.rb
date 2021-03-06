=begin rdoc
  Array extensions
=end

require "enumerator"
class Array
  def collect_with_index &block
    self.enum_for(:each_with_index).collect &block
  end

  # Example  nodes.select_with_hash(:status=>'running')
  def select_with_hash(conditions={})
    return self if conditions.empty?
    select do |node|
      conditions.any? do |k,v|
        ( node.has_key?(k) && node[k]==v ) or ( node.respond_to?(k) && node.send(k)==v )
      end
    end
  end
  
  def wrapping_next(id)
    raise "Element #{id} not in array" unless index(id)
    index(id) >= size-1 ? at(0) : at(index(id)+1)
  end
  
  # Swap elements of an array
  def swap!(a,b)
    self[a], self[b] = self[b], self[a]
    self
  end
  
  # Rotate an array
  # Example:
  #   arr = %w(a b c d e f)
  #   arr2 = arr.clone.rotate
  # 
  #   arr.zip(arr2) => 
  #   [["a", "b"], ["b", "c"], ["c", "d"], ["d", "e"], ["e", "f"], ["f", "a"]]  
  def rotate
    push shift
  end
  
  def zip_offset(offset=0)
    arr2 = self.dup
    
    out = []
    self.each_with_index do |ele,i|
      break if i == (self.size - offset)
      out[i] = [ele, arr2[i+1]]
    end
    out
  end
    
end