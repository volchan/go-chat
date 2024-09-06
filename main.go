package main

import (
	"html/template"
	"io"
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

type Templates struct {
	templates *template.Template
}

func (t *Templates) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
	return t.templates.ExecuteTemplate(w, name, data)
}

func newTemplate() *Templates {
	return &Templates{
		templates: template.Must(template.ParseGlob("views/*.html")),
	}
}

type Contact struct {
	Id       uuid.UUID
	Username string
	Email    string
}

func newContact(username, email string) *Contact {
	id := uuid.New()
	return &Contact{
		Id:       id,
		Username: username,
		Email:    email,
	}
}

type Contacts = []Contact

type Data struct {
	Contacts Contacts
}

func (d *Data) indexOf(id string) int {
	for i, contact := range d.Contacts {
		if contact.Id.String() == id {
			return i
		}
	}
	return -1
}

func newData() *Data {
	return &Data{
		Contacts: []Contact{
			*newContact("John Doe", "jd@gmail.com"),
			*newContact("Claire Doe", "cd@gmail.com"),
		},
	}
}

func (d *Data) hasEmail(email string) bool {
	for _, contact := range d.Contacts {
		if contact.Email == email {
			return true
		}
	}
	return false
}

type FormData struct {
	Values map[string]string
	Errors map[string]string
}

func newFormData() *FormData {
	return &FormData{
		Values: map[string]string{},
		Errors: map[string]string{},
	}
}

type Page struct {
	Title string
	Data  *Data
	Form  *FormData
}

func newPage(title string, data *Data, form *FormData) *Page {
	return &Page{
		Title: title,
		Data:  data,
		Form:  form,
	}
}

func main() {
	e := echo.New()

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.Static("/css", "css")
	e.Static("/images", "images")

	e.Renderer = newTemplate()

	page := newPage("Contacts", newData(), newFormData())

	e.GET("/", func(c echo.Context) error {
		return c.Render(http.StatusOK, "index", page)
	})

	e.POST("/contacts", func(c echo.Context) error {
		username := c.FormValue("username")
		email := c.FormValue("email")

		data := page.Data

		if page.Data.hasEmail(email) {
			formData := newFormData()
			formData.Values["Username"] = username
			formData.Values["Email"] = email
			formData.Errors["Email"] = "Email already exists"
			c.Logger().Error(formData)
			return c.Render(http.StatusUnprocessableEntity, "form", formData)
		}

		contact := newContact(username, email)
		c.Logger().Error(data.Contacts)
		data.Contacts = append(data.Contacts, *contact)
		c.Logger().Error(data.Contacts)
		c.Render(http.StatusOK, "form", newFormData())
		return c.Render(http.StatusOK, "oob-contact", contact)
	})

	e.DELETE("/contacts/:id", func(c echo.Context) error {
		id := c.Param("id")
		data := page.Data
		index := data.indexOf(id)

		if index == -1 {
			return c.String(http.StatusNotFound, "Contact not found")
		}

		data.Contacts = append(data.Contacts[:index], data.Contacts[index+1:]...)
		return c.NoContent(http.StatusOK)
	})

	e.Logger.Fatal(e.Start(":3000"))
}
