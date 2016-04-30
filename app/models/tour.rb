include ActionView::Helpers::DateHelper

class Tour < ActiveRecord::Base
  
  belongs_to :organizer
  belongs_to :where
  belongs_to :user
  belongs_to :category
  has_and_belongs_to_many :tags
  has_and_belongs_to_many :attractions
  has_and_belongs_to_many :confirmeds
  has_and_belongs_to_many :languages
  has_and_belongs_to_many :reviews, dependent: :destroy
  has_and_belongs_to_many :packages
  
  validates_presence_of :title, :organizer, :where
  
  scope :nexts, lambda { where("start >= ?", Time.now).order("start ASC") }
  
  scope :publisheds, -> { where(status: 'P') }
  
  # This method associates the attribute ":picture" with a file attachment
  has_attached_file :picture, styles: {
    thumbnail: '300x300>',
    square: '400x400#',
    cover: '600x800>',
    medium: '500x500>',
    large: '800x800>',
  }

  # Validate the attached image is image/jpg, image/png, etc
  validates_attachment_content_type :picture, :content_type => /\Aimage\/.*\Z/
  
  
  def how_long
    distance_words = distance_of_time_in_words(self.end - self.start)
    time_diff_components = Time.diff(self.end, self.start)
    if time_diff_components[:day] >= 1
      "de <strong>#{I18n.l(self.start, format: '%d de %B')} </strong> a <strong>#{I18n.l(self.end, format: '%d de %B')}</strong>".html_safe
    else
      "Duração total de <strong>#{distance_words}</strong>".html_safe
    end
  end
  
  def days
    time_diff_components = Time.diff(self.end, self.start)
    if time_diff_components[:day].to_i == 0
      I18n.l(self.start, format: '%d')
    else
      "#{I18n.l(self.start, format: '%d')} e #{I18n.l(self.end, format: '%d')}"
    end
  end
  
  def final_price(p)
    case self.currency
      when 'BRL'
        "<small>R$</small> " + p.to_s
      when 'US'
        "<small>$</small> " + p.to_s
      when 'EURO'
        "<small>€</small> " + p.to_s
      else
        p
    end
  end
  
  def to_param
    "#{id} #{title}".parameterize
  end
  
  def duration
    distance_of_time_in_words(self.end - self.start)
  end
  
  def days_left
     Time.diff(self.start, Time.now)[:day]
  end
  
  def level
    case self.difficulty
    when 1
      "muito fácil"
    when 2
      "fácil"
    when 3
      "moderada"
    when 4
      "difícil"
    when 5
      "muito difícil"
    else
      "não definida"
    end
  end
  
  def price
    if !self.try(:value)
      minor = 999999999
      if self.try(:packages)
        self.packages.each do |p|
          minor = p.value if p.value < minor 
        end
      end
      return "<small>A partir de R$</small> #{minor}"
    else
      case self.currency
      when 'BRL'
        "<small>R$</small> " + self.value.to_s
      when 'US'
        "<small>$</small> " + self.value.to_s
      when 'EURO'
        "<small>€</small> " + self.value.to_s
      else
      "<small>R$</small> " + self.value.to_s
    end
    end
  end
  
  def available
    if self.availability
     self.availability - self.confirmeds.count
    else
      0
    end
  end
  
  def soldout?
    self.available <= 0
  end
  
end
