<xsl:stylesheet version="1.0"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no"
              omit-xml-declaration="yes"/>

  <xsl:param name="chunk-size" select="42"/>

  <xsl:template name="escape">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="string-length($text)=0"/>
      <xsl:otherwise>
        <xsl:variable name="this" select="substring($text,1,$chunk-size)"/>
        <xsl:variable name="next" select="substring($text,$chunk-size+1)"/>
        <xsl:choose>
          <xsl:when test="contains($this,'&amp;') or
                          contains($this,'~') or
                          contains($this,'^') or
                          contains($this,'#') or
                          contains($this,'$') or
                          contains($this,'%') or
                          contains($this,'{') or
                          contains($this,'}') or
                          contains($this,'_') or
                          contains($this,'\')">
            <xsl:call-template name="scan">
              <xsl:with-param name="text" select="$this"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$this"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="escape">
          <xsl:with-param name="text" select="$next"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="scan">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="string-length($text)=0"/>
      <xsl:otherwise>
        <xsl:variable name="this" select="substring($text,1,1)"/>
        <xsl:variable name="next" select="substring($text,2)"/>
        <xsl:choose>
          <xsl:when test="contains('&amp;~^#$%{}_',$this)">
            <xsl:text>{\</xsl:text>
            <xsl:value-of select="$this"/>
            <xsl:text>}</xsl:text>
          </xsl:when>
          <xsl:when test="contains('\',$this)">
            <xsl:text>{\string\}</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$this"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="scan">
          <xsl:with-param name="text" select="$next"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xhtml:html">
    <xsl:apply-templates mode="head" select="xhtml:head"/>
    <xsl:apply-templates mode="body" select="xhtml:body"/>
  </xsl:template>

  <xsl:template mode="head" match="*">
    <xsl:if test="not(xhtml:meta[@name='DC.Publisher' and @content='青空文庫'])">
      <xsl:message terminate="no">警告: このファイルは青空文庫のXHTMLではありません</xsl:message>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="body" match="*">
    <xsl:apply-templates mode="meta" select="xhtml:div[@class='metadata']|."/>
    <xsl:apply-templates mode="text" select="xhtml:div[@class='main_text']"/>
  </xsl:template>

  <xsl:template mode="meta" match="*">
    <xsl:text>\title{</xsl:text>
    <xsl:value-of select="xhtml:h1[@class='title']"/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:text>\author{</xsl:text>
    <xsl:value-of select="xhtml:h2[@class='author']"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <xsl:template mode="text" match="*">
    <xsl:variable name="class" select="@class"/>
    <xsl:choose>
      <xsl:when test="contains(@style,'text-align:right')">
        <xsl:text>\right{</xsl:text>
        <xsl:apply-templates mode="text"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="$class='futoji'">
        <xsl:text>{\bf </xsl:text>
        <xsl:apply-templates mode="text"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="$class='shatai'">
        <xsl:text>{\it </xsl:text>
        <xsl:apply-templates mode="text"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="$class!='main_text' and $class">
        <xsl:text>\csname </xsl:text>
        <xsl:value-of select="normalize-space($class)"/>
        <xsl:text>\endcsname{</xsl:text>
        <xsl:apply-templates mode="text"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="text" match="text()">
    <xsl:call-template name="escape">
      <xsl:with-param name="text" select="normalize-space(.)"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template mode="text" match="xhtml:br">
    <xsl:text>{\par}&#10;</xsl:text>
  </xsl:template>

  <xsl:template mode="text" match="xhtml:ruby">
    <xsl:variable name="kanji">
      <xsl:for-each select="text()|xhtml:rb">
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:text>\ruby[</xsl:text>
    <xsl:choose>
      <xsl:when test="string-length($kanji)=1">
        <xsl:text>m</xsl:text>
      </xsl:when>
      <xsl:when test="count(xhtml:rt)=1">
        <xsl:text>g</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>j</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>]{</xsl:text>
    <xsl:call-template name="escape">
      <xsl:with-param name="text" select="$kanji"/>
    </xsl:call-template>
    <xsl:text>}{</xsl:text>
    <xsl:for-each select="xhtml:rt">
      <xsl:apply-templates mode="text" select="."/>
      <xsl:if test="position()!=last()">
        <xsl:text>|</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>}</xsl:text>
  </xsl:template>

</xsl:stylesheet>
