# Lets you write the Obsidian way:
#   [[Note name]], [[Note name|label]]  -> links to published notes/stories/pages
#   ![[image.png]]                      -> image from anywhere in the site folder
#   %%private comment%%                 -> removed from the website
# Links to notes that aren't published become plain text, so nothing breaks
# and nothing private leaks.

module ObsidianLinks
  class << self
    attr_reader :index, :files

    def build(site)
      @index = {}
      site.collections.each_value do |collection|
        collection.docs.each { |doc| @index[doc.basename_without_ext.downcase] = doc.url }
      end
      site.pages.each { |page| @index[File.basename(page.name, ".*").downcase] ||= page.url }
      @files = {}
      site.static_files.each { |file| @files[file.name.downcase] = file.url }
      @baseurl = site.baseurl.to_s.chomp("/")
    end

    def convert(text)
      text = text.gsub(/%%.*?%%/m, "")
      text = text.gsub(/!\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) do
        name, alt = Regexp.last_match(1).strip, Regexp.last_match(2)
        url = @files[File.basename(name).downcase]
        url ? "![#{alt || File.basename(name, '.*')}](#{@baseurl}#{url})" : ""
      end
      text.gsub(/\[\[([^\]|#]+)(#[^\]|]*)?(?:\|([^\]]+))?\]\]/) do
        name, heading, label = Regexp.last_match(1).strip, Regexp.last_match(2), Regexp.last_match(3)
        label ||= name
        url = @index[File.basename(name).downcase]
        url ? "[#{label}](#{@baseurl}#{url})" : label
      end
    end
  end
end

module PlainNotes
  # Notes moved in from Obsidian usually have no front matter. Jekyll would copy
  # those as raw files, so turn them into real pages. The date is when the file
  # first entered the repository (i.e. when it was published), falling back to
  # the file's modified time.
  def self.adopt(site)
    %w[notes stories articles].each do |label|
      collection = site.collections[label] or next
      collection.files.select { |f| %w[.md .markdown].include?(f.extname) }.each do |file|
        doc = Jekyll::Document.new(file.path, site: site, collection: collection)
        doc.read
        doc.data["date"] = published_at(site, file.path) if doc.data["date"].nil? || doc.data["date"] == site.time
        collection.docs << doc
        collection.files.delete(file)
        site.static_files.delete(file)
      end
      collection.docs.sort!
    end
  end

  def self.published_at(site, path)
    out = IO.popen(["git", "-C", site.source, "log", "--diff-filter=A", "--follow", "--format=%aI", "-1", "--", path], err: File::NULL, &:read).to_s.strip
    out.empty? ? File.mtime(path) : Time.parse(out)
  rescue StandardError
    File.mtime(path)
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  PlainNotes.adopt(site)
  # Use the Obsidian file name as the title, exactly as written
  # (Jekyll would otherwise Title Case Every Word).
  site.collections.each_value do |collection|
    collection.docs.each do |doc|
      name = doc.basename_without_ext
      doc.data["title"] = name if doc.data["title"] == Jekyll::Utils.titleize_slug(name)
    end
  end
  ObsidianLinks.build(site)
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |item|
  next unless item.respond_to?(:extname) && %w[.md .markdown].include?(item.extname)
  item.content = ObsidianLinks.convert(item.content)
end
