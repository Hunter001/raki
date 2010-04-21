# Raki - extensible rails-based wiki
# Copyright (C) 2010 Florian Schwab
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module PageHelper

  def page_contents(name, revision=nil)
    Raki.provider(:page).page_contents(name, revision)
  end

  def insert_page(name, revision=nil)
    if page_exists?(name, revision)
      parsed = Raki.parser(:page).parse(page_contents(name, revision))
      (parsed.nil?)?"<div class=\"error\">PARSING ERROR</div>":parsed
    end
  end

  def page_exists?(name, revision=nil)
    Raki.provider(:page).page_exists?(name, revision)
  end

  def page_revisions(name)
    Raki.provider(:page).page_revisions(name)
  end

end
