# :nodoc:
class UmmJsonForm < JsonFile
  attr_accessor :schema, :object

  def initialize(form_filename, schema, object, field_prefix: nil)
    super(form_filename)

    @schema = schema
    @object = object

    @field_prefix = field_prefix
  end

  def forms
    parsed_json.fetch('forms', []).map do |umm_form_section|
      if umm_form_section['type'] == 'section'
        UmmFormSection.new(umm_form_section, self, schema)
      elsif umm_form_section['type'] == 'fieldset'
        UmmFormFieldSet.new(umm_form_section, self, schema)
      else
        UmmFormElement.new(umm_form_section, self, schema)
      end
    end
  end

  # Get the value for the provided key from the provided object
  def get_element_value(key)
    # Uses reduce to dig through the provided object to look for and return the
    # provided key that could be nested
    schema.element_path_for_object(key).reduce(object) { |a, e| a[e] }
  rescue
    nil
  end
end

# :nodoc:
class UmmForm < JsonObj
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Context

  attr_accessor :form_section_json, :json_form, :schema, :title, :description, :children, :options

  def initialize(form_section_json, json_form, schema, options = {})
    super(form_section_json)

    @json_form = json_form
    @schema = schema
    @options = options

    @title = @parsed_json['title']
    @description = @parsed_json['description']

    @children = parsed_json.fetch('items', []).map do |value|
      # TODO: Determine a more dynamic way of instantiating these
      # classes using the type or another aspect of the json
      if value['type'] == 'section'
        UmmFormSection.new(value, json_form, schema)
      elsif value['type'] == 'fieldset'
        UmmFormFieldSet.new(value, json_form, schema)
      else
        UmmFormElement.new(value, json_form, schema)
      end
    end
  end

  def render_markup
    children.map(&:render_markup)
  end
end

# :nodoc:
class UmmFormSection < UmmForm
  def render_markup
    content_tag(:div, class: parsed_json['htmlClass']) do
      # Display a title for the section if its provided
      concat content_tag(:h4, title, class: 'space-bot') unless title.nil?

      # Display a description of the section if its provided
      concat content_tag(:p, description, class: 'form-description space-bot') unless description.nil?

      # Continue rendering fields that appear in this section
      children.each do |child_element|
        concat child_element.render_markup
      end
    end
  end
end

# :nodoc:
class UmmFormFieldSet < UmmForm
  def render_markup
    content_tag(:fieldset, class: parsed_json['htmlClass']) do
      # Display a title for the section if its provided
      concat content_tag(:h4, title, class: 'space-bot') unless title.nil?

      # Display a description of the section if its provided
      concat content_tag(:p, description, class: 'form-description space-bot') unless description.nil?

      # Continue rendering fields that appear in this section
      children.each do |child_element|
        concat child_element.render_markup
      end
    end
  end
end

# :nodoc:
class UmmFormElement < UmmForm
  # Returns all the properties necessary to operate jQuery Validation on the given element
  def validation_properties(element)
    # jQuery Validate can use html elements for validation so we'll set those elements
    # here instead of having to define these attributes on a one off basis in javascript
    validation_properties = element.select { |key| %w(minLength maxLength pattern).include?(key) }

    # JSON Schema provides the required fields in a separate array so we have to look this up
    if schema.required_field?(element['key'])
      validation_properties['required'] = true

      # jQuery validation supports custom messages via data attributes
      validation_properties['data'] = {
        'msg-required': "#{element['key'].titleize} is required."
      }
    end

    validation_properties
  end

  def element_classes(property, initial_classes: nil)
    # Default classes
    classes = initial_classes || 'full-width'

    # Add textcounter to the UI if the element has a maxLength
    classes << ' textcounter' if property.key?('maxLength')

    classes
  end

  def element_properties(element)
    {
      class: element_classes(element)
    }.merge(validation_properties(element))
  end

  # Locates the fragment of the schema that the provided key represents
  def schema_fragment
    schema.retrieve_schema_fragment(parsed_json['key'])
  end

  # Returns the fragment of the form json that represents this element
  def form_fragment
    parsed_json
  end

  def help_icon(path, title)
    link_to('#help-modal', class: 'display-modal') do
      concat content_tag(:i, nil, class: 'eui-icon eui-fa-info-circle', data: { 'help-path': path })
      concat content_tag(:span, "Help modal for #{title}", class: 'is-invisible')
    end
  end

  def render_markup
    capture do
      # Adds a label to the container holding the element
      concat UmmLabel.new(form_fragment, json_form, schema).render_markup

      # Adds the help modal link and icon
      concat help_icon("properties/#{form_fragment['key']}", form_fragment['key'])

      # Determine the class to use fo rendering this element
      element_class = form_fragment.fetch('type', 'UmmTextField')
      form_element = element_class.constantize.new(form_fragment, json_form, schema)

      concat form_element.render_markup
    end
  end
end
