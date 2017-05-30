Given(/^the user expects a result in a multi_find lookup$/) do
  elm = browser.multi_find(
    :selectors => [
      {:input => {:type => 'notexist'}},
      {:like => [:a, :text, 'Link']}
    ]
  )
  unless elm.text == 'Rel Link'
    error "Expected element with text `blog`, but received `#{elm.text}`"
  end
end

Given(/^the user expects an error in a multi_find lookup$/) do
  err = ''
  begin
    elm = browser.multi_find(
      :selectors => [
        {:input => {:type => 'notexist'}},
        {:like => [:a, :id, 'notexist2']}
      ]
    )
    err = "Expected an error looking for elements with no results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end

Given(/^the user expects no error in a multi_find lookup$/) do
  elm = browser.multi_find(
    :selectors => [
      {:input => {:type => 'notexist'}},
      {:like => [:a, :id, 'notexist2']}
    ],
    :throw => false
  )
  unless elm.nil?
    error "Expected the result to be nil."
  end
end

Given(/^the user expects 8 results in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
    :selectors => [
      {:like => [:div, :name, 'count']},
      {:like => [:a, :text, 'Link']}
    ]
  )
  unless elm.length == 8
    error "Expected 2 elements, but received `#{elm.length}`"
  end
end

Given(/^the user expects 1 results in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
    :selectors => [
      {:input => {:type => 'notexist'}},
      {:like => [:a, :text, 'Link']}
    ]
  )
  unless elm[0].text == 'Rel Link'
    error "Expected element with text `blog`, but received `#{elm.text}`"
  end
end

Given(/^the user expects 5 existing results in a multi_find_all lookup$$/) do
  elm = browser.multi_find_all(
    :selectors => [
      {:like => [:a, :id, 'notexists']},
      {:like => [:div, :name, 'count'], :filter_by => :exists?},
    ]
  )
  unless elm.length == 5
    error "Expected 5 elements, but received `#{elm.length}`"
  end
end

Given(/^the user expects an error in a multi_find_all lookup$/) do
  err = ''
  begin
    elm = browser.multi_find_all(
      :selectors => [
        {:input => {:type => 'notexist'}},
        {:like => [:a, :id, 'notexist2']}
      ]
    )
    err = "Expected an error looking for elements with no results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end

Given(/^the user expects no error in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
    :selectors => [
      {:input => {:type => 'notexist'}},
      {:like => [:a, :id, 'notexist2']}
    ],
    :throw => false
  )
  unless elm.length == 0
    error "Expected to receive 0 results."
  end
end

Given(/^the user expects an error in a multi_find_all lookup matching all elements$/) do
  err = ''
  begin
    elm = browser.multi_find_all(
      :selectors => [
        {:input => {:type => 'texta'}},
        {:like => [:a, :text, 'Link']}
      ],
      :mode => :match_all
    )
    err = "Expected an error matching all elements with results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end
Given(/^the user expects no error in a multi_find_all lookup matching all elements$/) do

  elm = browser.multi_find_all(
    :selectors => [
      {:input => {:type => 'texta'}},
      {:like => [:a, :text, 'Link']}
    ],
    :mode => :match_all,
    :throw => false
  )
  unless elm.length == 0
    error "Expected to receive 0 results."
  end
end