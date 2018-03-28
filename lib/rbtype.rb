require 'rbtype/ast/node'
require 'rbtype/ast/processor'
require 'rbtype/ast/sexp'

require 'rbtype/deps/file_loader'
require 'rbtype/deps/gems'
require 'rbtype/deps/spec_loader'

linters = Dir[File.join(File.dirname(__FILE__), 'rbtype/lint/*.rb')]
linters.each { |filename| require(filename) }

require 'rbtype/lexical/resolver'
require 'rbtype/lexical/const_reference'
require 'rbtype/lexical/expression'
require 'rbtype/lexical/instance_reference'

require 'rbtype/type/engine'
require 'rbtype/type/union_reference'

require 'rbtype/processors/tagger_base'
require 'rbtype/processors/type_identity'
require 'rbtype/processors/instantiation_tagger'
require 'rbtype/processors/const_reference_tagger'

require 'rbtype/runtime/class'
require 'rbtype/runtime/module'
require 'rbtype/runtime/object_space'
require 'rbtype/runtime/runtime'
require 'rbtype/runtime/undefined'
require 'rbtype/runtime/top_level'
require 'rbtype/runtime/named_object'
require 'rbtype/runtime/opaque_expression'
require 'rbtype/runtime/unresolved_constant'
require 'rbtype/runtime/constant_resolution_context'

require 'rbtype/processed_source'
require 'rbtype/cache'
require 'rbtype/version'
