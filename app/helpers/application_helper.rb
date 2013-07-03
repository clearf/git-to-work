module ApplicationHelper
  def format_date(date)
    return date.strftime("%m/%d/%y %H:%M")
  end

  def format_pct(number, inverse=false)
    if inverse
      ((1.0-number)*100.0).round()
    else
      (number*100.0).round()
    end
  end
end
